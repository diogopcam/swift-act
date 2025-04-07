//
//  main.swift
//  swift-test-act
//
//  Created by Diogo Pessin Camargo on 07/04/25.
//
import Foundation

let clientID = "06f8ada099474925bdfc9a6feb4cfecb"
let clientSecret = "ce3b74e7fb3c4ca9a68cd1b847ca3361"
let semaphore = DispatchSemaphore(value: 0)

struct TokenResponse: Decodable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}

struct SearchResponse: Decodable {
    let artists: Artists
}

struct Artists: Decodable {
    let items: [Artist]
}

struct Artist: Decodable {
    let name: String
    let popularity: Int
    let external_urls: ExternalURLs
    let images: [SpotifyImage]?
}

struct ExternalURLs: Decodable {
    let spotify: String
}

struct SpotifyImage: Decodable {
    let url: String
}

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
    
    let task = URLSession.shared.dataTask(with: request) { data, _, error in
        defer { semaphore.signal() }
        
        if let error = error {
            print("Erro na requisição do token: \(error.localizedDescription)")
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
            print("Erro ao decodificar token: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    task.resume()
}

func fetchSpotifyArtist() {
    // URL da API
    let urlString = "https://api.spotify.com/v1/artists/4Z8W4fKeB5YxbusRsdQVPb"
    guard let url = URL(string: urlString) else {
        print("URL inválida")
        return
    }
    
    // Token de autorização
    let token = "BQCvXMGpssTmE0ksLMEpc0sMyn1JoIOKDTaZpNquVsTj3Fgg8RBAhrXBGjvxatS54tGGyMMEoAiD-xjVdWcftjVDtrtYchNafJUi3-FAH2nI1H3bueWFH_8xsHlEo1v0YBIq-MBACYw"
    
    // Criar a requisição
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    // Criar a sessão e a tarefa de dados
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        // Verificar erros
        if let error = error {
            print("Erro na requisição: \(error.localizedDescription)")
            return
        }
        
        // Verificar resposta HTTP
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Resposta inválida")
            return
        }
        
        print("Status code: \(httpResponse.statusCode)")
        
        // Processar os dados recebidos
        if let data = data {
            do {
                // Tentar decodificar o JSON (supondo que a resposta é JSON)
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("Resposta JSON: \(json)")
                }
                
                // Ou se você tiver um struct/modelo para decodificar:
                // let decoder = JSONDecoder()
                // let artist = try decoder.decode(Artist.self, from: data)
                // print(artist)
            } catch {
                print("Erro ao decodificar JSON: \(error.localizedDescription)")
            }
        }
    }
    
    // Iniciar a tarefa
    task.resume()
}

// Chamar a função
fetchSpotifyArtist()

//
//// Executar
//getAccessToken { token in
//    if let token = token {
//        print("Token obtido com sucesso. \(token)")
//        // Chamar a função
//        fetchSpotifyArtist()
//    } else {
//        print("Não foi possível obter o token.")
//        semaphore.signal()
//    }
//}

semaphore.wait()
