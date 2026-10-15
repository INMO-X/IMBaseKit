//
//  IMExampleProfileService.swift
//  IMBaseKit Example
//
//  docs/USAGE.md §4。一个模块 = RequestTarget + Response + Provider。
//

import Foundation
import IMBaseKit
import Moya
import ObjectMapper

enum IMExampleProfileRequest {
    case detail(userId: String)
}

extension IMExampleProfileRequest: IMCommonRequestTarget {
    var baseURL: URL { URL(string: IMEnvironmentManager.shared.environment.baseUrlString)! }
    var path: String { "/api/v1/user/profile" }
    var sampleData: Data { Data() }
    var task: Task { .requestParameters(parameters: parameter ?? [:], encoding: JSONEncoding.default) }
    var parameter: [String: Any]? {
        switch self {
        case .detail(let userId):
            return ["userId": userId]
        }
    }
    var cache: CachePolicy { .netFirst }
    var showsDefaultAlertOnError: Bool { true }
}

final class IMExampleProfileResponse: IMCommonResponse {
    var nickname: String?

    override func mapping(map: Map) {
        super.mapping(map: map)
        nickname <- map["data.nickname"]
    }
}

final class IMExampleProfileService {
    private let provider = IMCommonProvider<IMExampleProfileRequest>(with: [
        IMLoggerPlugin(configuration: .init(logOptions: .verbose)),
        IMStatusCodeAlertPlugin()
    ])

    func fetch(userId: String, completion: @escaping (IMExampleProfileResponse?) -> Void) {
        provider.request(.detail(userId: userId), convertible: IMExampleProfileResponse.self) { response in
            completion(response)
        }
    }
}
