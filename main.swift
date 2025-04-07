//
//  main.swift
//  swift-test-act
//
//  Created by Diogo Pessin Camargo on 07/04/25.
//
import Foundation

let clientID = "06f8ada099474925bdfc9a6feb4cfecb"
let clientSecret = "ce3b74e7fb3c4ca9a68cd1b847ca3361"

let semaphore = DispatchSemaphore(value: 0)  // impede que o script finalize antes da resposta

func getAccessToken(completion: @escaping (String?) -> Void) {
    let authURL = URL(string: "https://accounts.spotify.com/api/token")!
    
    var request = URLRequest(url: authURL)
    request.httpMethod = "POST"
    
    let credentials = "\(clientID):\(clientSecret)"
    let encodedCredentials = Data(credentials.utf8).base64EncodedString()
    request.setValue("Basic \(encodedCredentials)", forHTTPHeaderField: "Authorization")
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    let bodyParams = "grant_type=client_credentials"
    request.httpBody = bodyParams.data(using: .utf8)
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() } // sinaliza que pode continuar

        if let error = error {
            print("Erro na requisição: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        guard let data = data else {
            print("Nenhum dado recebido.")
            completion(nil)
            return
        }
        
        do {
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            completion(tokenResponse.access_token)
        } catch {
            print("Erro ao decodificar resposta: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    task.resume()
}

struct TokenResponse: Decodable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}

// Testar
getAccessToken { token in
    if let token = token {
        print("Token de Acesso: \(token)")
    } else {
        print("Falha ao obter o token.")
    }
}

// O token está sendo printado corretamente. Gostaria agora de testar uma requisição para o Spotify



// Espera a requisição terminar
semaphore.wait()
