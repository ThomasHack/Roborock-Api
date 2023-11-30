//
//  RoborockURLSessionDelegate.swift
//  
//
//  Created by Hack, Thomas on 27.07.23.
//

import ComposableArchitecture
import Foundation

public class RoborockURLSessionDelegate: NSObject, URLSessionDelegate, URLSessionWebSocketDelegate {
    var continuation: AsyncStream<WebSocketClient.Action>.Continuation?

    public func urlSession(
        _: URLSession,
        webSocketTask _: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        self.continuation?.yield(.didOpen(protocol: `protocol`))
    }

    public func urlSession(
        _: URLSession,
        webSocketTask _: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        self.continuation?.yield(.didClose(code: closeCode, reason: reason))
        self.continuation?.finish()
    }

    public func urlSession(_ session: URLSession,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        let host = challenge.protectionSpace.host
        let trustedHosts = ["roborock.friday.home", "roborock"]
        if trustedHosts.contains(host) {
            // Check SSL certificate
            guard let trust = challenge.protectionSpace.serverTrust,
                  SecTrustGetCertificateCount(trust) > 0 else {
                print("No trusted remote certificate.")
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }

            // Load local certificate
            guard let certificatePath = Bundle.main.path(forResource: "friday", ofType: "cer"),
                  let pinnedCertificateData = NSData(contentsOfFile: certificatePath) else {
                print("Could not load local certificate")
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }

            // Load remote certificate chain
            guard let remoteCertificateChain = SecTrustCopyCertificateChain(trust) as? [SecCertificate] else {
                print("Could not load local certificate")
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }

            // Map remote certificate chain
            let remoteCertificatesData = Set(
                remoteCertificateChain.map { SecCertificateCopyData($0) as NSData }
            )

            // Check if remote chain contains local certificate
            if remoteCertificatesData.contains(pinnedCertificateData) {
                completionHandler(.useCredential, URLCredential(trust: trust))
            } else {
                print("Certificate does not match")
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
        } else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
    }
}
