//===-- Analyzer.cc - the kernel-analysis framework--------------===//
//
// This file implements the analysis framework. It calls the pass for
// building call-graph and the pass for finding security checks.
//
// ===-----------------------------------------------------------===//

#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/Support/ManagedStatic.h"
#include "llvm/Support/PrettyStackTrace.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/Signals.h"
#include <llvm/Support/ThreadPool.h>
#include <llvm/Demangle/Demangle.h>
#include <random>

#include "Analyzer.h"
#include "CallGraph.h"
#include "ClOptForward.h"
#include "EHBlockDetector.h"
#include "ErrorCheckViolationFinder.h"

// Command line parameters.
cl::list<string> InputFilenames(
    cl::Positional, cl::OneOrMore, cl::desc("<input bitcode files>"));

cl::opt<unsigned> VerboseLevel(
    "verbose-level", cl::desc("Print information at which verbose level"),
    cl::init(0));

cl::opt<unsigned int> ThreadCount(
        "c",
        cl::desc("The amount of threads to use"),
        cl::NotHidden, cl::init(2));

#if 1
cl::opt<float> AssociationConfidence(
        "st",
        cl::desc("Association analysis confidence between [0, 1]. The higher the more confident the association must be."),
        cl::NotHidden, cl::init(0.925f));
cl::opt<float> IntervalConfidenceThreshold(
        "interval-ct",
        cl::desc("Confidence threshold between [0, 1]. The higher the more similar the error intervals should be."),
        cl::NotHidden, cl::init(0.5f));
cl::opt<bool> ShowSafetyChecks(
        "ssc",
        cl::desc("Show safety checks."),
        cl::NotHidden, cl::init(false));
cl::opt<unsigned int> PrintRandomNonVoidFunctionSamples(
        "print-random-non-void-function-samples",
        cl::desc("How many random non-void function names to print, useful for sampling functions to compute a recall"),
        cl::NotHidden, cl::init(0));
cl::opt<bool> RefineWithVSA(
        "refine-vsa",
        cl::desc("Refine error intervals using VSA."),
        cl::NotHidden, cl::init(true));
cl::opt<float> IncorrectCheckThreshold(
        "incorrect-ct",
        cl::desc("Incorrect check threshold between [0, 1]."),
        cl::NotHidden, cl::init(0.725f));
cl::opt<float> MissingCheckThreshold(
        "missing-ct",
        cl::desc("Missing check threshold between [0, 1]."),
        cl::NotHidden, cl::init(0.725f));
#endif
cl::opt<MLTAMode> MLTA(
        "mlta-mode",
        cl::desc("Sets in which mode MLTA runs"),
        cl::values(
                clEnumVal(NoIndirectCalls, "No indirect call analysis"),
                clEnumVal(MatchSignatures, "Consider all matching type signatures as possible call targets"),
                clEnumVal(FullMLTA, "Full MLTA implementation")
        ),
        cl::NotHidden, cl::init(FullMLTA)
);

cl::opt<string> FunctionTestCasesToAnalyze(
        "function-test-cases-to-analyzer",
        cl::desc("An allowlist (comma separated) that specifies which functions to run through the analyzer as a means of testing."),
        cl::NotHidden, cl::init(""));

GlobalContext GlobalCtx;


void IterativeModulePass::run(ModuleMap &modules, bool multithreaded) {
  OP << "[" << ID << "] Initializing " << modules.size() << " modules ";
  bool again = true;
  while (again) {
    again = false;
    for (const auto& [module, _] : modules) {
      again |= doInitialization(module);
      OP << ".";
    }
  }
  OP << "\n";

  {
    OP << "[" << ID << " / " << 1 << "] ";

    if (multithreaded) {
        ThreadPool threadPool(hardware_concurrency(ThreadCount));
        for (auto&[module, _]: modules) {
            threadPool.async(&IterativeModulePass::_doModulePass, this, module);
        }
        threadPool.wait();
    } else {
        for (auto&[module, _]: modules) {
            _doModulePass(module);
        }
    }

    //OP << "[" << ID << "] Updated in " << changed << " modules.\n";
  }

  OP << "[" << ID << "] Postprocessing ...\n";
  again = true;
  while (again) {
    again = false;
    for (const auto& [m, _] : modules) {
      again |= doFinalization(m);
    }
  }

  OP << "[" << ID << "] Done!\n\n";
}

void loadModule(const char* argv[], unsigned i, mutex* modulesVectorMutex) {
    SMDiagnostic Err;
    auto LLVMCtx = new LLVMContext();
    unique_ptr<Module> M = parseIRFile(InputFilenames[i], Err, *LLVMCtx);

    if (!M) {
        OP << argv[0] << ": error loading file '"
           << InputFilenames[i] << "'\n";
        return;
    }

    Module *Module = M.release();
#if 0
    OP << "Amount of instructions in " << InputFilenames[i] << ": " << Module->getInstructionCount() << "\n";
#endif
    StringRef MName(strdup(InputFilenames[i].data()));
    lock_guard _(*modulesVectorMutex);
    GlobalCtx.Modules.insert({Module, MName});
}

int main(int argc, const char* argv[]) {
	// Print a stack trace if we signal out.
	sys::PrintStackTraceOnErrorSignal(argv[0]);
	PrettyStackTraceProgram X(argc, argv);

	llvm_shutdown_obj Y;  // Call llvm_shutdown() on exit.

	cl::ParseCommandLineOptions(argc, argv, "global analysis\n");

	// Loading modules
	OP << "Total " << InputFilenames.size() << " file(s)\n";

    OP << "IncorrectCheckThreshold = " << format("%.2f", IncorrectCheckThreshold * 100.0f) << "\n";
    OP << "MissingCheckThreshold = " << format("%.2f", MissingCheckThreshold * 100.0f) << "\n";

    mutex modulesVectorMutex;
    ThreadPool loadPool;
	for (unsigned i = 0; i < InputFilenames.size(); ++i) {
        loadPool.async(&loadModule, argv, i, &modulesVectorMutex);
	}
    loadPool.wait();

    if (PrintRandomNonVoidFunctionSamples > 0) {
        set<const Function*> functionsToSampleFrom;
        for (const auto& [module, _] : GlobalCtx.Modules) {
#if 1
            if (module->getName().contains("/libc.so.bc"))
                continue;
#endif
            for (const auto& F : *module) {
                if (F.empty())
                    continue;
                if (F.getReturnType()->isVoidTy())
                    continue;
                functionsToSampleFrom.insert(&F);
            }
        }

        vector<const Function*> samples;
        sample(functionsToSampleFrom.begin(), functionsToSampleFrom.end(), back_inserter(samples), PrintRandomNonVoidFunctionSamples.getValue(), mt19937{random_device{}()});
        LOG(LOG_INFO, "Sampled " << PrintRandomNonVoidFunctionSamples << " functions from a set of " << functionsToSampleFrom.size() << ":\n");
        for (const auto* F : samples) {
            LOG(LOG_INFO, "\t" << demangle(F->getName().str()) << "\n");
            if (auto subProgram = F->getSubprogram()) {
                LOG(LOG_INFO, "\t\tIn: " << subProgram->getFilename() << ": " << subProgram->getLine() << "\n");
            }
        }
    }

    // For rebuttal: count the number of functions in the modules
#if 1
    unsigned int totalCount = 0;
    unsigned int totalCountNonVoid = 0;
    for (const auto& [module, _] : GlobalCtx.Modules) {
#if 1
        if (module->getName().contains("/libc.so.bc"))
            continue;
#endif
        totalCount += count_if(*module, [](const auto& function) { return !function.empty(); });
        totalCountNonVoid += count_if(*module, [](const auto& function) { return !function.empty() && !function.getReturnType()->isVoidTy(); });
    }
    OP << "Total number of functions: " << totalCount << "\n";
    OP << "Total number of non-void functions: " << totalCountNonVoid << "\n";
#endif

    {
        CallGraphPass CGPass(&GlobalCtx);
        CGPass.run(GlobalCtx.Modules);
    }

    {
        EHBlockDetectorPass EHPass(&GlobalCtx);
        EHPass.run(GlobalCtx.Modules, true);
        EHPass.nextStage();
        EHPass.associationAnalysisForErrorHandlers();
        EHPass.run(GlobalCtx.Modules, true);
        EHPass.storeData();
        EHPass.learnErrorsFromErrorBlocksForSelf();
        EHPass.propagateCheckedErrors();
    }

    {
        ErrorCheckViolationFinderPass ECVFPass(&GlobalCtx);
        ECVFPass.run(GlobalCtx.Modules);
        ECVFPass.nextStage();
        ECVFPass.run(GlobalCtx.Modules);
        ECVFPass.determineTruncationBugs();
        ECVFPass.determineSignednessBugs();
        ECVFPass.finish();
    }

    // Cleanup memory to keep ASAN etc. happy
    for (const auto& [function, pairs] : GlobalCtx.functionToSanityValuesAndConditions) {
        for (const auto& [_, abstractComparison] : pairs) {
            delete abstractComparison;
        }
    }
    for (const auto& [function, aa] : GlobalCtx.AAPass) {
        delete aa;
    }

	return 0;
}

