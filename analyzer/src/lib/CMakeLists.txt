set (AnalyzerSourceCodes
	Common.h
	Common.cc
	Analyzer.h
	Analyzer.cc
	CallGraph.h
	CallGraph.cc
	ClOptForward.h
	EHBlockDetector.cc
	EHBlockDetector.h
	DataFlowAnalysis.h
	DataFlowAnalysis.cc
	Helpers.h
	Helpers.cc
	DebugHelpers.h
	DebugHelpers.cc
	Lazy.h
	Interval.cc
	Interval.h
	FunctionErrorReturnIntervals.cc
	FunctionErrorReturnIntervals.h
	ErrorCheckViolationFinder.cc
	ErrorCheckViolationFinder.h
	PathSpan.h FunctionVSA.cc FunctionVSA.h)

set(CMAKE_MACOSX_RPATH 0)

# Build libraries.
add_library (AnalyzerObj OBJECT ${AnalyzerSourceCodes})
#add_library (Analyzer SHARED $<TARGET_OBJECTS:AnalyzerObj>)
#add_library (AnalyzerStatic STATIC $<TARGET_OBJECTS:AnalyzerObj>)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")

# Build executable.
set (EXECUTABLE_OUTPUT_PATH ${ANALYZER_BINARY_DIR})
link_directories (${ANALYZER_BINARY_DIR}/lib)
add_executable(kanalyzer ${AnalyzerSourceCodes})
target_link_libraries(kanalyzer 
	LLVMAsmParser 
	LLVMSupport 
	LLVMCore 
	LLVMAnalysis
	LLVMIRReader
	LLVMDemangle
)
