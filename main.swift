//
//  main.swift
//  swift-act-spotify
//
//  Created by ticpucrs on 07/04/25.
//

// Fluxo:
// - Token expirou? Rodar apenas getAccessToken
// - Token do uso do player expirou?
// https://accounts.spotify.com/authorize?client_id=06f8ada099474925bdfc9a6feb4cfecb&response_type=code&redirect_uri=http://localhost:8080/callback&scope=user-read-playback-state%20user-modify-playback-state
 //- Acessar o valor ao lado de CODE= (exemplo:         /*http://localhost:8080/callback?code=AQCepbRcgWYBLk0KBwR_DiB9tlfStJeTG5zIzLFby-KEqdXRdU4a6tsXHxP5vpK1EkUfr6FeUpKEsBEm3aTWdQwgEuk34incM2TzzrMFp-pD6JHTtmU4z03kUWok6lmEOQitQodSheyuML8f80faCq0G_Gj7k-RgQTJ2yQ-QmhNRBT6rf-WNZRSS1HoZKGwFacLxH4XbsU4z3Af9BnqMP-gnqAn4tTUPXMqGhINNP_Jk84Js59rIqA)*/
// - Fazer a seguinte requisicao utilizando o CODE e as credenciais client_id e client_secret
//        curl -X POST https://accounts.spotify.com/api/token \
//          -H "Content-Type: application/x-www-form-urlencoded" \
//          -d "grant_type=authorization_code" \
//          -d "code=AQB360Etb1_mQwTHSaE8QzsJZAkE7MNArjI00sp3BPeb5toEXoaBK8t44VwnvL_m52q_ollSE62lFW39LSpPBg5i1tYXMqD1anuytTYkEjUxhAcx9RjxoTs3E6h0FQpqflfHNmZbjT8rXx7qJteTFHhq_U6pu4wo2b_FE5K0bm1DRMLP4WvqUZmqZW55dV3M8K6SG_0JCWu4JrR8eX2tzI6yhcdwmkHWhDlJkdWuhay2JzJJZwlSGQ" \
//          -d "redirect_uri=http://localhost:8080/callback" \
//          -d "client_id=06f8ada099474925bdfc9a6feb4cfecb" \
//          -d "client_secret=ce3b74e7fb3c4ca9a68cd1b847ca3361"

// - Se tudo correu bem, você deve receber o access_token que deverá ser utilizado para controlar o player:
//{"access_token":"BQCMqMxTqMJ6jHpMXTR3rHaxuc5XwmfpoazBQLbJ7WW_yP7UNHV4NKizL51j6bWZ0UTvSAaJdMsz_--tyGEIqX8nS-ML-MjnAllQWK4lnOmGNuYMVUb7BOkyQLyIr9lRYIreO3UQNlNwj40oTqufweJj3Ce4nygmFLdh9ztE4kYmV5E0yKzvg6o6RhuHm_VLXwmvu3ll7MT9NQtbnVKMkk0xjf9FblwR-__WjEI4QL0kMP8","token_type":"Bearer","expires_in":3600,"refresh_token":"AQDjfWRaOLWyrouW3GhBPQYEpnJckcNjA2vniiwswoTp3YE5AW8xlJw6YXOhdFYYacrrSxSTwxPwsBpiiA_CJugZHWIH4tOGzJSmOAOnRrxDx6lkeum6R7IoOgS0ZfbXGsg","scope":"user-modify-playback-state user-read-playback-state"}

import Foundation

let clientID = "06f8ada099474925bdfc9a6feb4cfecb"
let clientSecret = "ce3b74e7fb3c4ca9a68cd1b847ca3361"
let semaphore = DispatchSemaphore(value: 0)

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

var token: String = "BQBVdSznFc4AEOxJj_JrGlPIvYvmmfMnIXsUEgxQzyFhSgGu3-jsr-F-cANZ9fZs0GsOsuFH7rur7uotHXZfnrf9is8RTtMuhzdzNKo6C3q9FnzNd-3O0QyqS6zYytXboxZzlM7JSRM"

// ------ FLUXO DE AUTENTICACAO PARA USAR O PLAYER -----
// Endereço para conseguir o token de usuário
let getTokenAdress = "https://accounts.spotify.com/authorize?client_id=06f8ada099474925bdfc9a6feb4cfecb&response_type=code&redirect_uri=http://localhost:8080/callback&scope=user-read-playback-state%20user-modify-playback-state"

// Tokens e credenciais relacionadas ao meu usuário
let tokenUser = "AQB360Etb1_mQwTHSaE8QzsJZAkE7MNArjI00sp3BPeb5toEXoaBK8t44VwnvL_m52q_ollSE62lFW39LSpPBg5i1tYXMqD1anuytTYkEjUxhAcx9RjxoTs3E6h0FQpqflfHNmZbjT8rXx7qJteTFHhq_U6pu4wo2b_FE5K0bm1DRMLP4WvqUZmqZW55dV3M8K6SG_0JCWu4JrR8eX2tzI6yhcdwmkHWhDlJkdWuhay2JzJJZwlSGQ"

// Resposta da requisição após o uso do token
let accessTokenPlayer = "BQDoD5rk4tQsFx2JkwkNbLOINg00IEB2mS-6g-tZn7ePNprZ2v3Pb1jcgAgW9IzrBBm9h_15Oltdqhxi_90on4c32LOUzJIoNpYH_c3H-xe5IZcXi5PcGLcqQX3qzr8yEWy17RcFykb47NQ3I8lr1XlcvvHZ-NLv64vsQUPuHZxL3gib16WRjepZ-NzhFmT0_Q7VOtVKHyQRyXJxf4QwhSVVVPWzBpSyjt5piUuHOiAugzU"
//
//"token_type":"Bearer","expires_in":3600,"refresh_token":"AQCddcWRuF9RXPQa2vTiEvBBKcEjQMEgzKq-X6U2lasAi8iU4nQcjQKToyXNdNsZBMimiZ66KDwNBhCO8l6EtpgFPnb57ByRZbeascI87qZBzN1UZm8CMwA8UmV0F2pYyEY","scope":"user-modify-playback-state user-read-playback-state"
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

struct TracksResponse: Codable {
    let items: [TrackResponse]
    // Lista com todas as tracks
    let total: Int
    // Total de faixas
}

struct TrackResponse: Codable {
    let durationMs: Int  // camelCase na propriedade Swift
    let id: String
    let name: String
    let trackNumber: Int  // camelCase na propriedade Swift
    let uri: String
    
    private enum CodingKeys: String, CodingKey {
        case durationMs = "duration_ms"  // mapeia para snake_case do JSON
        case id
        case name
        case trackNumber = "track_number"  // mapeia para snake_case do JSON
        case uri
    }
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

func fetchAlbumTracks(_ albumId: String, completion: @escaping ([TrackResponse]?, Error?) -> Void) {
    let urlString = "https://api.spotify.com/v1/albums/\(albumId)/tracks"
    
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
        
        if let jsonString = String(data: data, encoding: .utf8) {
//            print("\n📦 JSON da resposta da API:\n\(jsonString)")
            
            do {
                       let decoder = JSONDecoder()
                       let response = try decoder.decode(TracksResponse.self, from: data)
                       completion(response.items, nil)
                   } catch {
                       print("Erro ao decodificar JSON: \(error)")
                       completion(nil, error)
                   }
            
        } else {
            print("⚠️ Não foi possível converter os dados para string.")
        }
        
        // Não retorna nada, só imprime
        completion(nil, nil)
    }.resume()
}

// --- FUNÇÕES DE DISPLAY ---
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

func displayTracks(_ tracks: [TrackResponse], from album: AlbumItem) {
    let separator = "✧" + String(repeating: "━", count: 50) + "✧"
    let smallSeparator = "┄" + String(repeating: "─", count: 48) + "┄"
    
    print("\n\(separator)")
    print("   🎶 TRACKLIST: \(album.name.uppercased())")
    print(separator)
    
    // Cabeçalho
    print("   #    DURAÇÃO   TÍTULO")
    print(smallSeparator)
    
    // Lista de faixas
    for (index, track) in tracks.enumerated() {
        let trackNumber = String(format: "%02d", index + 1)
        let duration = formatDuration(track.durationMs)
        
        print("   \(trackNumber)   \(duration)   \(track.name)")
        
        // Adiciona um separador a cada 5 faixas para melhor legibilidade
        if (index + 1) % 5 == 0 && index != tracks.count - 1 {
            print(smallSeparator)
        }
    }
    
    print(separator)
    print("   🎵 Total de faixas listadas: \(tracks.count)")
    print(separator)
}

// Função auxiliar para formatar a duração (ms → mm:ss)
private func formatDuration(_ milliseconds: Int) -> String {
    let seconds = milliseconds / 1000
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    return String(format: "%02d:%02d", minutes, remainingSeconds)
}

// --- FUNÇÕES RELACIONADAS AO PLAYER ---
func getAvailableDevices(completion: @escaping ([Device]?, Error?) -> Void) {
    let urlString = "https://api.spotify.com/v1/me/player/devices"
    
    guard let url = URL(string: urlString) else {
        completion(nil, NSError(domain: "URL inválida", code: 400, userInfo: nil))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(accessTokenPlayer)", forHTTPHeaderField: "Authorization")
    
    print("\n🔍 Buscando dispositivos disponíveis...")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("❌ Erro na requisição: \(error.localizedDescription)")
            completion(nil, error)
            return
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

func playTrackOnDevice(deviceId: String, token: String, uris: [String]) {
    guard let url = URL(string: "https://api.spotify.com/v1/me/player/play?device_id=\(deviceId)") else {
        print("URL inválida para tocar a faixa")
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("Bearer \(accessTokenPlayer)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = ["uris": uris]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        print("Erro ao criar corpo da requisição: \(error)")
        return
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Erro ao tocar faixa: \(error.localizedDescription)")
            return
        }

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 204 {
                print("Faixa tocando com sucesso no dispositivo: \(deviceId)")
            } else {
                print("Erro ao tocar faixa. Código de status: \(httpResponse.statusCode)")
                if let data = data, let body = String(data: data, encoding: .utf8) {
                    print("Resposta: \(body)")
                }
            }
        }
    }.resume()
}

// -- FUNÇÕES PARA CHAMAR AS REQUISIÇÕES ---
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

func tocarFaixa(deviceId: String, token: String, uris: [String]) {
    guard let url = URL(string: "https://api.spotify.com/v1/me/player/play?device_id=\(deviceId)") else {
        print("URL inválida para tocar a faixa")
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = ["uris": uris]

    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        print("Erro ao criar corpo da requisição: \(error)")
        return
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("❌ Erro ao tocar faixa: \(error.localizedDescription)")
            return
        }

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 204 {
                print("✅ Faixa tocando com sucesso no dispositivo: \(deviceId)")
            } else {
                print("⚠️ Erro ao tocar faixa. Código de status: \(httpResponse.statusCode)")
                if let data = data, let body = String(data: data, encoding: .utf8) {
                    print("Resposta: \(body)")
                }
            }
        }
    }.resume()
}

// ---- MENU ----
// Pegando o token inicial
//getAccessToken { token in
//    if var token = token {
//        print("Token obtido com sucesso. \(token)")
//        token = token
//        // Chamar a função
//    } else {
//        print("Não foi possível obter o token.")
////        semaphore.signal()
//    }
//}

//pegarFaixasDoAlbum(albumId: "3mH6qwIy9crq0I9YQbOuDf")
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
                
                print("Qual álbum você deseja escutar?")
                if let indexString = readLine(), let index = Int(indexString) {
//                    let albumId = albums[index].id
                    let selectedAlbum = albums[index - 1]
                    print("\n🎶 Preparando para tocar o álbum \(albums[index - 1].name)...")
                    
                    fetchAlbumTracks(selectedAlbum.id) { tracks, error in
                        
                        if let error = error {
                            print("❌ Erro ao buscar músicas: \(error.localizedDescription)")
                            return
                        }
                        
                        guard let tracks = tracks, !tracks.isEmpty else {
                            print("⚠️ Nenhuma música encontrada para o álbum.")
                            return
                        }
                        
                        displayTracks(tracks, from: selectedAlbum)
                        // SELECIONAR MÜSICA
                        print("Selecione a música que deseja tocar: ")
                        if let mscString = readLine(), let msc = Int(mscString) {
                            
                            let selectedMsc = tracks[msc - 1]
                            print()
                            print("Preparando para tocar a música \(tracks[msc - 1].name)")
                            
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
                                print("Em qual dispositivo você deseja tocar a música?")
                                
                                if let indexDevice = readLine(), let index = Int(indexDevice){
                                    
                                    let selectedDevice = devices[index - 1]
                                    
                                    tocarFaixa(deviceId: selectedDevice.id ?? "", token: accessTokenPlayer, uris: [selectedMsc.uri])
                                }
                            }
                          //  let meuDeviceId
//                            tocarFaixa(deviceId: meuDeviceId, token: accessTokenPlayer, uris: [selectedMsc.uri])
                            
                        }
                    
                    }
                }
            }

        } else {
            print("Artista não encontrado.")
        }
    }
} else {
    print("Nome do artista não pode ser vazio!")
}

//testarDispositivos()

// Executar

//let meuDeviceId = "3f81d536a323a687be993b0d4fd6eb527768fbf2"
//let musicas = ["spotify:track:3n3Ppam7vgaVa1iaRUc9Lp"]
//
//tocarFaixa(deviceId: meuDeviceId, token: accessTokenPlayer, uris: musicas)

semaphore.wait()
