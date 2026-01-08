import Foundation

struct JSONRPCRequest: Encodable {
    let jsonrpc: String = "2.0"
    let id: Int
    let method: String
    let params: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case jsonrpc, id, method, params
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encode(id, forKey: .id)
        try container.encode(method, forKey: .method)
        
        if let params = params {
            let jsonData = try JSONSerialization.data(withJSONObject: params)
            let jsonObject = try JSONDecoder().decode(AnyCodable.self, from: jsonData)
            try container.encode(jsonObject, forKey: .params)
        }
    }
}

struct JSONRPCResponse: Codable {
    let jsonrpc: String
    let id: Int?
    let result: AnyCodable?
    let error: JSONRPCError?
}

struct JSONRPCError: Codable {
    let code: Int
    let message: String
    let data: AnyCodable?
}

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

class JSONRPCClient {
    private var buffer = Data()
    private var requestId = 0
    private var pendingRequests: [Int: CheckedContinuation<JSONRPCResponse, Error>] = [:]
    
    func sendRequest(method: String, params: [String: Any]?) async throws -> JSONRPCResponse {
        requestId += 1
        let id = requestId
        
        let request = JSONRPCRequest(id: id, method: method, params: params)
        let encoder = JSONEncoder()
        var data = try encoder.encode(request)
        
        // Add Content-Length header (JSON-RPC over stdio convention)
        let contentLength = "Content-Length: \(data.count)\r\n\r\n"
        var message = contentLength.data(using: .utf8)!
        message.append(data)
        
        return try await withCheckedThrowingContinuation { continuation in
            pendingRequests[id] = continuation
        }
    }
    
    func getMessageToSend(method: String, params: [String: Any]?) throws -> Data {
        requestId += 1
        let id = requestId
        
        let request = JSONRPCRequest(id: id, method: method, params: params)
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        
        let contentLength = "Content-Length: \(data.count)\r\n\r\n"
        var message = contentLength.data(using: .utf8)!
        message.append(data)
        
        return message
    }
    
    func handleIncomingData(_ data: Data) {
        buffer.append(data)
        
        while let response = extractNextResponse() {
            if let id = response.id, let continuation = pendingRequests.removeValue(forKey: id) {
                if let error = response.error {
                    continuation.resume(throwing: NSError(domain: "JSONRPCError", code: error.code, userInfo: [NSLocalizedDescriptionKey: error.message]))
                } else {
                    continuation.resume(returning: response)
                }
            }
        }
    }
    
    private func extractNextResponse() -> JSONRPCResponse? {
        guard let headerEnd = buffer.range(of: "\r\n\r\n".data(using: .utf8)!) else {
            return nil
        }
        
        let headerData = buffer[..<headerEnd.lowerBound]
        guard let headerString = String(data: headerData, encoding: .utf8),
              let contentLength = parseContentLength(from: headerString) else {
            return nil
        }
        
        let bodyStart = headerEnd.upperBound
        let bodyEnd = bodyStart.advanced(by: contentLength)
        
        guard buffer.count >= bodyEnd else {
            return nil
        }
        
        let bodyData = buffer[bodyStart..<bodyEnd]
        buffer.removeSubrange(..<bodyEnd)
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(JSONRPCResponse.self, from: bodyData)
        } catch {
            return nil
        }
    }
    
    private func parseContentLength(from header: String) -> Int? {
        let lines = header.components(separatedBy: "\r\n")
        for line in lines {
            if line.hasPrefix("Content-Length:") {
                let parts = line.components(separatedBy: ":")
                if parts.count == 2, let length = Int(parts[1].trimmingCharacters(in: .whitespaces)) {
                    return length
                }
            }
        }
        return nil
    }
}
