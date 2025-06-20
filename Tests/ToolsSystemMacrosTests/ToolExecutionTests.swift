//
//  ToolExecutionTests.swift
//  ToolsSystemMacrosTests
//
//  Created by Morisson Marcel on 11/06/25.
//

import Foundation
import Testing
import ToolsSystemMacros
import ToolsSystem

// Import sqrt function for verification
import Darwin

@Test("TestTool executes correctly with empty arguments")
func testTestToolExecution() async throws {
    let tool = TestTool()
    let emptyArguments: [TestTool.Argument] = []
    
    let result = try await tool.call(arguments: emptyArguments)
    
    if case .string(let value) = result {
        #expect(value == "test result")
    } else {
        #expect(Bool(false), "Expected string result")
    }
}

@Test("CalcSquareRoot executes correctly with valid input")
func testCalcSquareRootExecution() async throws {
    let tool = CalcSquareRoot()
    let inputArgument = CalcSquareRoot.InputArgument(number: 9.0)
    let arguments = [inputArgument]
    
    let result = try await tool.call(arguments: arguments)
    
    if case .double(let value) = result {
        #expect(value == 3.0)
    } else {
        #expect(Bool(false), "Expected double result")
    }
}

@Test("CalcSquareRoot executes correctly with decimal input")
func testCalcSquareRootDecimalExecution() async throws {
    let tool = CalcSquareRoot()
    let inputArgument = CalcSquareRoot.InputArgument(number: 2.0)
    let arguments = [inputArgument]
    
    let result = try await tool.call(arguments: arguments)
    
    if case .double(let value) = result {
        // sqrt(2) ≈ 1.414213562373095
        #expect(abs(value - sqrt(2.0)) < 0.000001)
    } else {
        #expect(Bool(false), "Expected double result")
    }
}

@Test("CalcSquareRoot handles zero input")
func testCalcSquareRootZeroExecution() async throws {
    let tool = CalcSquareRoot()
    let inputArgument = CalcSquareRoot.InputArgument(number: 0.0)
    let arguments = [inputArgument]
    
    let result = try await tool.call(arguments: arguments)
    
    if case .double(let value) = result {
        #expect(value == 0.0)
    } else {
        #expect(Bool(false), "Expected double result")
    }
}

@Test("CalcSquareRoot handles large input")
func testCalcSquareRootLargeExecution() async throws {
    let tool = CalcSquareRoot()
    let inputArgument = CalcSquareRoot.InputArgument(number: 100.0)
    let arguments = [inputArgument]
    
    let result = try await tool.call(arguments: arguments)
    
    if case .double(let value) = result {
        #expect(value == 10.0)
    } else {
        #expect(Bool(false), "Expected double result")
    }
}

@Test("CalcSquareRoot throws error with empty arguments")
func testCalcSquareRootEmptyArgumentsError() async {
    let tool = CalcSquareRoot()
    let emptyArguments: [CalcSquareRoot.Argument] = []
    
    await #expect(throws: ToolError.noArguments) {
        _ = try await tool.call(arguments: emptyArguments)
    }
}

@Test("Tool argument decode works correctly")
func testToolArgumentDecoding() throws {
    let inputArgument = CalcSquareRoot.InputArgument(number: 25.0)
    let arguments = [inputArgument]
    
    let decoded = try arguments.decode(CalcSquareRoot.InputArgument.self)
    #expect(decoded.number == 25.0)
}

@Test("Tool argument decode throws error with wrong type")
func testToolArgumentDecodingWrongType() {
    let testArgument = TestTool.Argument() // EmptyArgument
    let arguments = [testArgument]
    
    #expect(throws: ToolError.invalidArgumentType) {
        _ = try arguments.decode(CalcSquareRoot.InputArgument.self)
    }
}

@Test("CalcSquareRoot end-to-end with JSON serialization")
func testCalcSquareRootEndToEnd() async throws {
    // Create input argument
    let inputArgument = CalcSquareRoot.InputArgument(number: 16.0)
    
    // Test that argument is codable
    let encoder = JSONEncoder()
    let argumentData = try encoder.encode(inputArgument)
    
    let decoder = JSONDecoder()
    let decodedArgument = try decoder.decode(CalcSquareRoot.InputArgument.self, from: argumentData)
    #expect(decodedArgument.number == 16.0)
    
    // Execute tool
    let tool = CalcSquareRoot()
    let result = try await tool.call(arguments: [decodedArgument])
    
    // Test result
    if case .double(let value) = result {
        #expect(value == 4.0)
    } else {
        #expect(Bool(false), "Expected double result")
    }
    
    // Test that result is codable
    let resultData = try encoder.encode(result)
    let decodedResult = try decoder.decode(ToolOutput.self, from: resultData)
    
    if case .double(let decodedValue) = decodedResult {
        #expect(decodedValue == 4.0)
    } else {
        #expect(Bool(false), "Expected double result after decoding")
    }
}

@Test("Tool definition can be serialized")
func testToolDefinitionSerialization() throws {
    let definition = CalcSquareRoot.definition
    
    // Test serialization
    let encoder = JSONEncoder()
    let data = try encoder.encode(definition)
    
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(ToolDefinition.self, from: data)
    
    #expect(decoded.name == "calculate_square_root")
    #expect(decoded.description == "Calculates the square root of a number")
}

// Async tool defined at module level for testing
@Tool("async_delay_tool", "A tool that simulates async work with delay")
struct AsyncDelayTool: Sendable {
    func call(arguments: [Argument]) async throws -> ToolOutput {
        // Simulate async work
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        return .string("async completed")
    }
}

@Test("Async tool with network delay simulation")
func testAsyncToolWithDelay() async throws {
    let tool = AsyncDelayTool()
    let start = Date()
    let result = try await tool.call(arguments: [])
    let elapsed = Date().timeIntervalSince(start)
    
    if case .string(let value) = result {
        #expect(value == "async completed")
        #expect(elapsed >= 0.1, "Should take at least 0.1 seconds")
    } else {
        #expect(Bool(false), "Expected string result")
    }
}