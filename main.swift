//
//  main.swift
//  swift-act-spotify
//
//  Created by ticpucrs on 07/04/25.
//

import Foundation

let token = "BQAEkkyv7qHBr78LuS5iiNOBNqUQhkCn5nPbs0uCFaTd3LFlV7QQaA81yVs0tl7j3Qru4mzb_y7XObQ4yCyV2Kmi69nlVvicx9jyBWTqENQc78cyz0zg7fVl5q-I07qvuxfZe4F_HFI"

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

struct ArtistaResponse1: Codable {
    var artists: ArtistaResponse
}

struct ArtistaResponse: Codable {
    var items: [ArtistItem]
}


struct Artista: Codable {
    var name: String
    var idade: Int
}

struct ArtistItem: Codable {
    var id: String
    var name: String
    
}

struct Album: Decodable {
    let id: String
    let album_name: String
    let album_type: String
    let release_date: String
    let total_tracks: Int
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
    let urlString = "https://api.spotify.com/v1/artists/2h93pZq0e7k5yf4dywlkpM"
    
    guard let url = URL(string: urlString) else {
        print("URL inválida")
        return
    }
    
    // Token de autorização
    let token = "BQDpzLb-_Hskg0nYY4MNoj3HDNv4pAjVzTKGbt97kgkdPpoFtXl3Fw8MNPd6Azl0z_vZmDokYkgtzNpFxgY02zAuGaSYdfGNjcbHsZl38jqBY066pP1ROiQyUD4vZDG0fw5KbgFIzHI"
    
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
            } catch {
                print("Erro ao decodificar JSON: \(error.localizedDescription)")
            }
        }
    }
    
    // Iniciar a tarefa
    task.resume()
}

func searchArtistByName(_ artistName: String, completion: @escaping (String?, String?, Error?) -> Void) {
    // 1. Codificar o nome do artista para URL
    let encodedName = artistName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    
    // 2. Construir a URL de busca (apenas por artista)
    let urlString = "https://api.spotify.com/v1/search?q=\(encodedName)&type=artist&limit=1"
    
    guard let url = URL(string: urlString) else {
        completion(nil, nil, NSError(domain: "URL inválida", code: 400, userInfo: nil))
        return
    }
    
    // 3. Configurar a requisição com token de acesso
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    // 4. Fazer a requisição
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(nil, nil, error)
            return
        }
        
        guard let data = data else {
            completion(nil, nil, NSError(domain: "Dados não recebidos", code: 404, userInfo: nil))
            return
        }
        
        do {
            // 5. Processar a resposta

            
            let artistResponse = try JSONDecoder().decode(ArtistaResponse1.self, from: data)
            
            guard let artista = artistResponse.artists.items.first else {
                completion(nil,nil,nil)
                return
            }
            
            completion(artista.id, artista.name, nil)
        } catch {
            completion(nil, nil, error)
        }
    }.resume()
}

func fetchArtistAlbums(artistId: String, completion: @escaping ([Album]?, Error?) -> Void) {
    // 1. Construir a URL para buscar álbuns do artista
    let urlString = "https://api.spotify.com/v1/artists/\(artistId)/albums?limit=50"
    
    guard let url = URL(string: urlString) else {
        completion(nil, NSError(domain: "URL inválida", code: 400, userInfo: nil))
        return
    }
    
    // 2. Configurar a requisição
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    // 3. Fazer a requisição
    URLSession.shared.dataTask(with: request) { data, response, error in
        // Tratar erro de conexão
        if let error = error {
            completion(nil, error)
            return
        }
        
        // Verificar se recebeu dados
        guard let data = data else {
            completion(nil, NSError(domain: "Nenhum dado recebido", code: 404, userInfo: nil))
            return
        }
        
        // 4. Processar a resposta
        do {
            
            let artistResponse = try JSONDecoder().decode(ArtistaResponse.self, from: data)
            print(artistResponse.items.first?.name)
//            if let json = try JSONSDecoder.decode(AlbumRewith: data) as? ArtistaResponse.self,
//               let albums = json["items"] as? [[String: Any]] {
//                
//                // Filtrar apenas álbuns (não singles/compilações)
//                let filteredAlbums = albums.filter { album in
//                    let albumType = album["album_type"] as? String ?? ""
//                    return albumType == "album"
//                }
//                
//                completion(filteredAlbums, nil)
//            } else {
//                completion(nil, NSError(domain: "Formato de resposta inválido", code: 500, userInfo: nil))
//            }
        } catch {
            completion(nil, error)
        }
    }.resume()
}

// ---- MENU ----
print("Seja bem-vindo ao Terminalfy! Digite o nome do artista:")
let artistName = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

if !artistName.isEmpty {
    print("\n🔍 Buscando artista: \(artistName)...")
    
    searchArtistByName(artistName) { id, name, error in
        if let error = error {
            print("Erro: \(error.localizedDescription)")
        } else if let id = id, let name = name {
            print("\n✅ Artista encontrado!")
            print("Nome: \(name)")
            print("ID: \(id)")
            
            // ---- CHAMADA PARA BUSCAR ALBUNS DO ARTISTA PESQUISADO ----
            fetchArtistAlbums(artistId: id) { albums, error in
                if let error = error {
                    print("Erro ao buscar álbuns: \(error.localizedDescription)")
                    return
                }
                
                guard let albums = albums, !albums.isEmpty else {
                    print("Nenhum álbum encontrado.")
                    return
                }
                
                print("\nÁlbuns encontrados:")
                
                for (index, album) in albums.enumerated() {
                    print("Tentando printar o album: \(index + 1). \(album)")
//                    print("   📅 Lançamento: \(album.release_date)")
//                    print("   🎵 Faixas: \(album.total_tracks)")
                    
//                    if let imageUrl = album.images?.first?.url {
//                        print("   🖼️ Capa: \(imageUrl)")
//                    }
                    
                    print("----------------------------------")
                }
            }
            
        } else {
            print("Artista não encontrado.")
        }
    }
} else {
    print("Nome do artista não pode ser vazio!")
}

////// Executar
//getAccessToken { token in
//    if let token = token {
//        print("Token obtido com sucesso. \(token)")
//        // Chamar a função
//    } else {
//        print("Não foi possível obter o token.")
//        semaphore.signal()
//    }
//}

semaphore.wait()
