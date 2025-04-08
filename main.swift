//
//  main.swift
//  swift-act-spotify
//
//  Created by ticpucrs on 07/04/25.
//

import Foundation

let token = "BQBwe7mBgv-GsNhqLTLtqsAKYYvuQtryf7eTQqfRZCLRTitUGXxBIjzoZMMQ3Y78jLOymh8pD8mgnEDzKZ5dSO37e-lurqlKwK0EUhPJuUt94GFSBEi59zaa-m4bK4lgnNYrBTp3hHQ"

let clientID = "06f8ada099474925bdfc9a6feb4cfecb"
let clientSecret = "ce3b74e7fb3c4ca9a68cd1b847ca3361"
let semaphore = DispatchSemaphore(value: 0)


// ------ FLUXO DE AUTENTICACAO PARA USAR O PLAYER -----
// Endereço para conseguir o token de usuário
let getTokenAdress = "https://accounts.spotify.com/authorize?client_id=06f8ada099474925bdfc9a6feb4cfecb&response_type=code&redirect_uri=http://localhost:8080/callback&scope=user-read-playback-state%20user-modify-playback-state"

// Tokens e credenciais relacionadas ao meu usuário
let tokenUser = "AQCepbRcgWYBLk0KBwR_DiB9tlfStJeTG5zIzLFby-KEqdXRdU4a6tsXHxP5vpK1EkUfr6FeUpKEsBEm3aTWdQwgEuk34incM2TzzrMFp-pD6JHTtmU4z03kUWok6lmEOQitQodSheyuML8f80faCq0G_Gj7k-RgQTJ2yQ-QmhNRBT6rf-WNZRSS1HoZKGwFacLxH4XbsU4z3Af9BnqMP-gnqAn4tTUPXMqGhINNP_Jk84Js59rIqA"

// Resposta da requisição após o uso do token
let accessTokenPlayer = "BQCMqMxTqMJ6jHpMXTR3rHaxuc5XwmfpoazBQLbJ7WW_yP7UNHV4NKizL51j6bWZ0UTvSAaJdMsz_--tyGEIqX8nS-ML-MjnAllQWK4lnOmGNuYMVUb7BOkyQLyIr9lRYIreO3UQNlNwj40oTqufweJj3Ce4nygmFLdh9ztE4kYmV5E0yKzvg6o6RhuHm_VLXwmvu3ll7MT9NQtbnVKMkk0xjf9FblwR-__WjEI4QL0kMP8"
// {"access_token":"BQCMqMxTqMJ6jHpMXTR3rHaxuc5XwmfpoazBQLbJ7WW_yP7UNHV4NKizL51j6bWZ0UTvSAaJdMsz_--tyGEIqX8nS-ML-MjnAllQWK4lnOmGNuYMVUb7BOkyQLyIr9lRYIreO3UQNlNwj40oTqufweJj3Ce4nygmFLdh9ztE4kYmV5E0yKzvg6o6RhuHm_VLXwmvu3ll7MT9NQtbnVKMkk0xjf9FblwR-__WjEI4QL0kMP8","token_type":"Bearer","expires_in":3600,"refresh_token":"AQDjfWRaOLWyrouW3GhBPQYEpnJckcNjA2vniiwswoTp3YE5AW8xlJw6YXOhdFYYacrrSxSTwxPwsBpiiA_CJugZHWIH4tOGzJSmOAOnRrxDx6lkeum6R7IoOgS0ZfbXGsg","scope":"user-modify-playback-state user-read-playback-state"}%

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

struct TrackResponse: Codable {
    let tracks: TrackItems
}

struct TrackItems: Codable {
    let items: [Track]
}

struct Track: Codable {
    let id: String
    let name: String
    let preview_url: String?
    let artists: [Artist]
    let album: AlbumItem
}

struct Device: Codable {
    let id: String?
    let is_active: Bool
    let name: String
}

struct DevicesResponse: Codable {
    let devices: [Device]
}

struct PlaybackContext: Codable {
    let device: Device?
    let is_playing: Bool
}

struct PlayRequest: Codable {
    let uris: [String]?
    let context_uri: String?
    let offset: [String: Int]?
    let position_ms: Int?
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

func getTrackById(trackId: String, completion: @escaping (Track?, Error?) -> Void) {
    let urlString = "https://api.spotify.com/v1/tracks/\(trackId)"
    
    guard let url = URL(string: urlString) else {
        completion(nil, NSError(domain: "URL inválida", code: 400, userInfo: nil))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(nil, error)
            return
        }
        
        guard let data = data else {
            completion(nil, NSError(domain: "Nenhum dado recebido", code: 404, userInfo: nil))
            return
        }
        
        do {
            let track = try JSONDecoder().decode(Track.self, from: data)
            completion(track, nil)
        } catch {
            completion(nil, error)
        }
    }.resume()
}

// Adicione esta função ao seu código existente
func testarDispositivos() {
    print("\n🔍 Buscando dispositivos disponíveis no Spotify...")
    
    getAvailableDevices { devices, error in
        if let error = error {
            print("\n❌ Erro ao buscar dispositivos: \(error.localizedDescription)")
            semaphore.signal()
            return
        }
        
        guard let devices = devices, !devices.isEmpty else {
            print("\n⚠️ Nenhum dispositivo do Spotify encontrado.")
            print("Certifique-se que o Spotify está aberto em algum dispositivo (app desktop, web ou mobile)")
            semaphore.signal()
            return
        }
        
        print("\n✅ Dispositivos encontrados:")
        for (index, device) in devices.enumerated() {
            print("\n\(index + 1). \(device.name)")
            print("   🔹 ID: \(device.id ?? "N/A")")
            print("   🔹 Status: \(device.is_active ? "Ativo" : "Inativo")")
        }
        
        semaphore.signal()
    }
    
    semaphore.wait()
}

//// Modifique seu menu principal para incluir a opção de teste
//func showMainMenu() {
//    print("\n✧ Terminalfy - Menu Principal ✧")
//    print("1. Buscar artista")
//    print("2. Buscar música por nome")
//    print("3. Tocar música por ID")
//    print("4. Testar dispositivos Spotify")
//    print("5. Sair")
//    print("Escolha uma opção: ", terminator: "")
//    
//    if let choice = readLine(), let option = Int(choice) {
//        switch option {
//        case 1:
//            searchArtistFlow()
//        case 2:
//            searchTrackFlow()
//        case 3:
//            print("\nDigite o ID da música: ", terminator: "")
//            if let trackId = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) {
//                selectDeviceAndPlay(trackId: trackId)
//            }
//        case 4:
//            testarDispositivos()
//        case 5:
//            exit(0)
//        default:
//            print("Opção inválida!")
//        }
//    }
//    showMainMenu()
//}

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

func getAvailableDevices(completion: @escaping ([Device]?, Error?) -> Void) {
    let urlString = "https://api.spotify.com/v1/me/player/devices"
    
    guard let url = URL(string: urlString) else {
        completion(nil, NSError(domain: "URL inválida", code: 400, userInfo: nil))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(accessTokenPlayer)", forHTTPHeaderField: "Authorization")
    
    print("🔍 Fazendo requisição para: \(urlString)")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("❌ Erro na requisição: \(error.localizedDescription)")
            completion(nil, error)
            return
        }
        
        // Debug: imprimir resposta HTTP
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Status Code: \(httpResponse.statusCode)")
            print("📡 Headers: \(httpResponse.allHeaderFields)")
        }
        
        guard let data = data else {
            print("⚠️ Nenhum dado recebido")
            completion(nil, NSError(domain: "Nenhum dado recebido", code: 404, userInfo: nil))
            return
        }
        
        // Debug: imprimir resposta bruta
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 Resposta bruta: \(jsonString)")
        } else {
            print("⚠️ Não foi possível converter dados para string")
        }
        
        do {
            let response = try JSONDecoder().decode(DevicesResponse.self, from: data)
            completion(response.devices, nil)
        } catch let decodingError {
            print("❌ Erro na decodificação: \(decodingError)")
            completion(nil, decodingError)
        }
    }.resume()
}

func playTrackOnDevice(trackId: String, deviceId: String? = nil, completion: @escaping (Bool, Error?) -> Void) {
    let urlString: String
    if let deviceId = deviceId {
        urlString = "https://api.spotify.com/v1/me/player/play?device_id=\(deviceId)"
    } else {
        urlString = "https://api.spotify.com/v1/me/player/play"
    }
    
    guard let url = URL(string: urlString) else {
        completion(false, NSError(domain: "URL inválida", code: 400, userInfo: nil))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let playRequest = PlayRequest(uris: ["spotify:track:\(trackId)"], context_uri: nil, offset: nil, position_ms: nil)
    
    do {
        request.httpBody = try JSONEncoder().encode(playRequest)
    } catch {
        completion(false, error)
        return
    }
    
    URLSession.shared.dataTask(with: request) { _, response, error in
        if let error = error {
            completion(false, error)
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            completion(httpResponse.statusCode == 204, nil)
        } else {
            completion(false, NSError(domain: "Resposta inválida", code: 500, userInfo: nil))
        }
    }.resume()
}

func selectDeviceAndPlay(trackId: String) {
    getAvailableDevices { devices, error in
        if let error = error {
            print("Erro ao buscar dispositivos: \(error.localizedDescription)")
            return
        }
        
        guard let devices = devices, !devices.isEmpty else {
            print("Nenhum dispositivo do Spotify encontrado. Por favor, abra o Spotify em algum dispositivo.")
            return
        }
        
        print("\nDispositivos disponíveis:")
        for (index, device) in devices.enumerated() {
            print("\(index + 1). \(device.name)\(device.is_active ? " (Ativo)" : "")")
        }
        
        print("\nDigite o número do dispositivo ou 0 para usar o dispositivo ativo: ", terminator: "")
        
        if let choice = readLine(), let option = Int(choice) {
            if option == 0 {
                // Usar dispositivo ativo
                if let activeDevice = devices.first(where: { $0.is_active }) {
                    playTrackOnDevice(trackId: trackId, deviceId: activeDevice.id) { success, error in
                        if success {
                            print("\n🎵 Tocando música no \(activeDevice.name)!")
                        } else {
                            print("Erro ao reproduzir música: \(error?.localizedDescription ?? "Desconhecido")")
                        }
                    }
                } else {
                    print("Nenhum dispositivo ativo encontrado.")
                }
            } else if option > 0 && option <= devices.count {
                // Usar dispositivo selecionado
                let device = devices[option - 1]
                playTrackOnDevice(trackId: trackId, deviceId: device.id) { success, error in
                    if success {
                        print("\n🎵 Tocando música no \(device.name)!")
                    } else {
                        print("Erro ao reproduzir música: \(error?.localizedDescription ?? "Desconhecido")")
                    }
                }
            } else {
                print("Opção inválida!")
            }
        }
    }
}

// ---- MENU ----
//print("Seja bem-vindo ao Terminalfy! Digite o nome do artista:")
//let artistName = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
//
//if !artistName.isEmpty {
//    print("\n🔍 Buscando artista: \(artistName)...")
//    
//    searchArtistByName(artistName) { id, name, error in
//        if let error = error {
//            print("Erro: \(error.localizedDescription)")
//        } else if let id = id, let name = name {
//            print("\n✅ Artista encontrado!")
//            print("Nome: \(name)")
//            print("ID: \(id)")
//            
//            // ---- CHAMADA PARA BUSCAR ALBUNS DO ARTISTA PESQUISADO ----
//            fetchArtistAlbums(id) { albums, error in
//                if let error = error {
//                    print("Erro ao buscar álbuns: \(error.localizedDescription)")
//                    return
//                }
//                
//                guard let albums = albums, !albums.isEmpty else {
//                    print("Nenhum álbum encontrado.")
//                    return
//                }
//                
//                print("\nÁlbuns encontrados:")
//                
//                for (index, album) in albums.enumerated() {
//                    displayAlbum(album, index: index)
//                }
//            }
//            
//        } else {
//            print("Artista não encontrado.")
//        }
//    }
//} else {
//    print("Nome do artista não pode ser vazio!")
//}
testarDispositivos()

// Executar
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
