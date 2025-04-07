//
//  main.swift
//  swift-act-spotify
//
//  Created by ticpucrs on 07/04/25.
//

import Foundation

let token = "BQDxa9fg8AJfyETzSwsp8Sl8w2-U6vih_Eo-l6uqF4h03xf0hP-7y3jmoEC2C_ZPnlihtfltiqs-FPbZSL_r7-PFuifjwiQPVnnNaRc4zu2OpjlPL8FRz9izy4lBTg6Sqnycv8Nr1pA"

let clientID = "06f8ada099474925bdfc9a6feb4cfecb"
let clientSecret = "ce3b74e7fb3c4ca9a68cd1b847ca3361"
let semaphore = DispatchSemaphore(value: 0)

struct TokenResponse: Decodable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}

// CORPO GERAL DA REQUISIÇÃO
struct ArtistBodyResponse: Codable {
    var artists: ArtistResponse
}

// ITEMS (COISA DO ARTISTA)
struct ArtistResponse: Codable {
    var items: [ArtistItem]
}

// DADOS QUE REALMENTE DESEJAMOS ACESSAR
struct ArtistItem: Codable {
    var id: String
    var name: String
}


// LISTA COM TODOS OS ALBUNS
struct AlbumResponse: Codable {
    let href: String
    let items: [AlbumItem]
    let limit: Int
    let next: String?
    let offset: Int
    let previous: String?
    let total: Int
}

// DADOS QUE REALMENTE DESEJAMOS ACESSAR
// Estrutura para cada item de álbum
struct AlbumItem: Codable {
    let album_type: String
    let total_tracks: Int
    let id: String
    let name: String
    let release_date: String
    let release_date_precision: String
    let type: String
    let artists: [Artist]
    let images: [SpotifyImage]?
    
    // Você pode remover isso se não for usar
    let available_markets: [String]?
    let external_urls: ExternalURLs?
    let uri: String?
    let album_group: String?
}

struct Album: Decodable {
    let id: String
    let album_name: String
    let album_type: String
    let release_date: String
    let total_tracks: Int
    let images: [SpotifyImage]?
}

struct Artist: Codable {
    let external_urls: ExternalURLs?
    let href: String?
    let id: String
    let name: String
    let type: String
    let uri: String?
}

struct ExternalURLs: Codable {
    let spotify: String
}

struct SpotifyImage: Codable {
    let url: String
    let height: Int?
    let width: Int?
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
            let artistResponse = try JSONDecoder().decode(ArtistBodyResponse.self, from: data)
            
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

func fetchArtistAlbums(_ artistId: String, completion: @escaping ([AlbumItem]?, Error?) -> Void) {
    // 1. Construir a URL para buscar álbuns do artista
    let urlString = "https://api.spotify.com/v1/artists/\(artistId)/albums?limit=50&include_groups=album"
    
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
            print("Deu merda 1")
            completion(nil, error)
            return
        }
        
        // Verificar se recebeu dados
        guard let data = data else {
            print("Deu merda 2")
            completion(nil, NSError(domain: "Nenhum dado recebido", code: 404, userInfo: nil))
            return
        }
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Resposta da API:\n\(jsonString)")
        } else {
            print("Não foi possível converter os dados para string")
        }
        
        // 4. Processar a resposta
        do {
            let albumResponse = try JSONDecoder().decode(AlbumResponse.self, from: data)
            
            // --- FILTRO AQUI ---
               let filteredAlbums = albumResponse.items.filter { item in
                   item.album_group == "album" ||
                   item.artists.contains(where: { $0.id == artistId })
               }
            
            completion(filteredAlbums, nil)

        } catch {
            print("Deu merda 3")
            completion(nil, error)
        }
    }.resume()
}


func displayAlbum(_ album: AlbumItem, index: Int) {
    let separator = "✧" + String(repeating: "━", count: 50) + "✧"
    
    print("\n\(separator)")
    print("   🎵 Álbum #\(index + 1)")
    print(separator)
    
    // Informações básicas
    print("   💿 Nome: \(album.name)")
    print("   🏷️  Tipo: \(album.album_type.capitalized)")
    print("   📅 Lançamento: \(album.release_date)")
    print("   🎵 Total de faixas: \(album.total_tracks)")
    print("   🆔 ID: \(album.id)")
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
            fetchArtistAlbums(id) { albums, error in
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
                    displayAlbum(album, index: index)
                }
            }
            
        } else {
            print("Artista não encontrado.")
        }
    }
} else {
    print("Nome do artista não pode ser vazio!")
}

//// Executar
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
