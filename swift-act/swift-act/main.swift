//
//  main.swift
//  swift-act
//
//  Created by ticpucrs on 04/04/25.
//

import Foundation
import Alamofire

// Substitua pelos seus dados do Spotify
let clientID = "06f8ada099474925bdfc9a6feb4cfecb"
let clientSecret = "ce3b74e7fb3c4ca9a68cd1b847ca3361"
let redirectURI = "http://localhost:8888/callback"

// Função para obter o token de acesso
func getAccessToken(completion: @escaping (String?) -> Void) {
    let authURL = "https://accounts.spotify.com/api/token"
    
    let parameters: [String: Any] = [
        "grant_type": "client_credentials"
    ]
    
    let headers: HTTPHeaders = [
        "Authorization": "Basic \(encodeBase64(clientID: clientID, clientSecret: clientSecret))"
    ]
    
    AF.request(authURL, method: .post, parameters: parameters, headers: headers)
        .validate()  // Valida a resposta, para garantir que foi bem-sucedida
        .responseDecodable(of: TokenResponse.self) { response in  // Decodifica diretamente em um objeto TokenResponse
            switch response.result {
            case .success(let tokenResponse):
                completion(tokenResponse.access_token)  // Acessa diretamente o token decodificado
            case .failure(let error):
                print("Erro na requisição: \(error.localizedDescription)")
                completion(nil)
            }
        }
}

// Função para codificar o clientID e clientSecret para Base64
func encodeBase64(clientID: String, clientSecret: String) -> String {
    let credentials = "\(clientID):\(clientSecret)"
    let data = credentials.data(using: .utf8)!
    return data.base64EncodedString()
}

// Definição do tipo para o JSON de resposta
struct TokenResponse: Decodable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}

// Testar a requisição
getAccessToken { token in
    if let token = token {
        print("Token de Acesso: \(token)")
    } else {
        print("Falha ao obter o token.")
    }
}
