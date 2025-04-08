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
//          -d "code=AQCjoNDwCQsU8KAq8xgN33tnRrndIfY-bqs7XOZhWbizhbKRS8ss17gqWXwHVKDNYXk6Qh9YQo15EDbctPeBC3ZR_xno4FiZrVmC8Np1xgBT93IhB_uIzNsliP-64GJanwyBUlNx1vU6kScZkI52BJLfYR9tB4adEcUf4ZrKRZgwA-vTsmxTeBEezaTPzg5TLtFCnWklx0QfJ0cenA21skOvU3IdQfpWEFIqLd0833RcCPqv66cvVg" \
//          -d "redirect_uri=http://localhost:8080/callback" \
//          -d "client_id=06f8ada099474925bdfc9a6feb4cfecb" \
//          -d "client_secret=ce3b74e7fb3c4ca9a68cd1b847ca3361"

// - Se tudo correu bem, você deve receber o access_token que deverá ser utilizado para controlar o player:
//{"access_token":"BQCMqMxTqMJ6jHpMXTR3rHaxuc5XwmfpoazBQLbJ7WW_yP7UNHV4NKizL51j6bWZ0UTvSAaJdMsz_--tyGEIqX8nS-ML-MjnAllQWK4lnOmGNuYMVUb7BOkyQLyIr9lRYIreO3UQNlNwj40oTqufweJj3Ce4nygmFLdh9ztE4kYmV5E0yKzvg6o6RhuHm_VLXwmvu3ll7MT9NQtbnVKMkk0xjf9FblwR-__WjEI4QL0kMP8","token_type":"Bearer","expires_in":3600,"refresh_token":"AQDjfWRaOLWyrouW3GhBPQYEpnJckcNjA2vniiwswoTp3YE5AW8xlJw6YXOhdFYYacrrSxSTwxPwsBpiiA_CJugZHWIH4tOGzJSmOAOnRrxDx6lkeum6R7IoOgS0ZfbXGsg","scope":"user-modify-playback-state user-read-playback-state"}

import Foundation

// MARK: - Configurações
let clientID = "06f8ada099474925bdfc9a6feb4cfecb"
let clientSecret = "ce3b74e7fb3c4ca9a68cd1b847ca3361"
let redirectURI = "http://localhost:8080/callback"
let scopes = "user-read-playback-state user-modify-playback-state"

// MARK: - Variáveis Globais
var token: String = ""
var refreshToken: String?
var tokenExpiration: Date?
var isAuthenticated = false

// MARK: - Estruturas
struct TokenResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let refresh_token: String
    let scope: String
}

struct ArtistBodyResponse: Codable {
    var artists: ArtistResponse
}

struct ArtistResponse: Codable {
    var items: [ArtistItem]
}

struct ArtistItem: Codable {
    var id: String
    var name: String
}

struct AlbumResponse: Codable {
    let href: String
    let items: [AlbumItem]
    let limit: Int
    let next: String?
    let offset: Int
    let previous: String?
    let total: Int
}

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
    let available_markets: [String]?
    let external_urls: ExternalURLs?
    let uri: String?
    let album_group: String?
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
    let total: Int
}

struct TrackResponse: Codable {
    let durationMs: Int
    let id: String
    let name: String
    let trackNumber: Int
    let uri: String
    
    private enum CodingKeys: String, CodingKey {
        case durationMs = "duration_ms"
        case id
        case name
        case trackNumber = "track_number"
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

// MARK: - Funções de Autenticação
func startAuthentication(completion: @escaping (Bool) -> Void) {
    let authURL = "https://accounts.spotify.com/authorize?client_id=\(clientID)&response_type=code&redirect_uri=\(redirectURI)&scope=\(scopes)"
    
    print("\n🔑 Abra este URL no seu navegador para autorizar:")
    print(authURL)
    print("\nApós autorizar, cole a URL completa de redirecionamento aqui:")
    
    guard let input = readLine() else {
        print("❌ Nenhuma entrada fornecida")
        completion(false)
        return
    }
    
    guard let code = extractCode(from: input) else {
        print("❌ URL inválida ou código não encontrado")
        completion(false)
        return
    }
    
    requestTokens(with: code, completion: completion)
}

func requestTokens(with code: String, completion: @escaping (Bool) -> Void) {
    let tokenURL = "https://accounts.spotify.com/api/token"
    var request = URLRequest(url: URL(string: tokenURL)!)
    request.httpMethod = "POST"
    
    let credentials = "\(clientID):\(clientSecret)".data(using: .utf8)!.base64EncodedString()
    request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    let body = "grant_type=authorization_code&code=\(code)&redirect_uri=\(redirectURI)"
    request.httpBody = body.data(using: .utf8)
    
    URLSession.shared.dataTask(with: request) { data, _, error in
        if let error = error {
            print("❌ Erro na requisição: \(error.localizedDescription)")
            completion(false)
            return
        }
        
        guard let data = data else {
            print("⚠️ Nenhum dado recebido")
            completion(false)
            return
        }
        
        do {
            let response = try JSONDecoder().decode(TokenResponse.self, from: data)
            token = response.access_token
            refreshToken = response.refresh_token
            tokenExpiration = Date().addingTimeInterval(TimeInterval(response.expires_in))
            
            print("\n✅ Autenticação concluída! Token válido por \(response.expires_in/60) minutos")
            print("✅ Esse é o token: \(token)")
            completion(true)
        } catch {
            print("❌ Erro ao decodificar resposta: \(error)")
            completion(false)
        }
    }.resume()
}

func extractCode(from urlString: String) -> String? {
    guard let url = URL(string: urlString),
          let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
        return nil
    }
    return code
}

// MARK: - Funções da API
func searchArtistByName(_ artistName: String, completion: @escaping (String?, String?, Error?) -> Void) {
    let encodedName = artistName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    let urlString = "https://api.spotify.com/v1/search?q=\(encodedName)&type=artist&limit=1"
    
    guard let url = URL(string: urlString) else {
        completion(nil, nil, NSError(domain: "URL inválida", code: 400, userInfo: nil))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    print("Esse é o token sendo chamado para puxar artista: \(token)")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Deu merda 1")
            completion(nil, nil, error)
            return
        }
        
        guard let data = data else {
            print("Deu merda 2")
            completion(nil, nil, NSError(domain: "Dados não recebidos", code: 404, userInfo: nil))
            return
        }
        
        do {
            let artistResponse = try JSONDecoder().decode(ArtistBodyResponse.self, from: data)
            
            guard let artista = artistResponse.artists.items.first else {
                print("Deu merda 3")
                completion(nil,nil,nil)
                return
            }
            
            print("ESSA É A RESPOSTA: \(artista)")
            completion(artista.id, artista.name, nil)
        } catch {
            print("Deu merda 4")
            completion(nil, nil, error)
        }
    }.resume()
}

func fetchArtistAlbums(_ artistId: String, completion: @escaping ([AlbumItem]?, Error?) -> Void) {
    let urlString = "https://api.spotify.com/v1/artists/\(artistId)/albums?limit=50&include_groups=album"
    
    guard let url = URL(string: urlString) else {
        completion(nil, NSError(domain: "URL inválida", code: 400, userInfo: nil))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Deu merda 1")
            completion(nil, error)
            return
        }
        
        guard let data = data else {
            print("Deu merda 2")
            completion(nil, NSError(domain: "Nenhum dado recebido", code: 404, userInfo: nil))
            return
        }
        
        if let jsonString = String(data: data, encoding: .utf8) {
            //print("Resposta da API:\n\(jsonString)")
        } else {
            print("Não foi possível converter os dados para string")
        }
        
        do {
            let albumResponse = try JSONDecoder().decode(AlbumResponse.self, from: data)
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
    }.resume()
}

// MARK: - Funções de Display
func displayAlbum(_ album: AlbumItem, index: Int) {
    let separator = "✧" + String(repeating: "━", count: 50) + "✧"
    
    print("\n\(separator)")
    print("   🎵 Álbum #\(index + 1)")
    print(separator)
    
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
    
    print("   #    DURAÇÃO   TÍTULO")
    print(smallSeparator)
    
    for (index, track) in tracks.enumerated() {
        let trackNumber = String(format: "%02d", index + 1)
        let duration = formatDuration(track.durationMs)
        
        print("   \(trackNumber)   \(duration)   \(track.name)")
        
        if (index + 1) % 5 == 0 && index != tracks.count - 1 {
            print(smallSeparator)
        }
    }
    
    print(separator)
    print("   🎵 Total de faixas listadas: \(tracks.count)")
    print(separator)
}

private func formatDuration(_ milliseconds: Int) -> String {
    let seconds = milliseconds / 1000
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    return String(format: "%02d:%02d", minutes, remainingSeconds)
}

// MARK: - Funções do Player
func getAvailableDevices(completion: @escaping ([Device]?, Error?) -> Void) {
    let urlString = "https://api.spotify.com/v1/me/player/devices"
    
    guard let url = URL(string: urlString) else {
        completion(nil, NSError(domain: "URL inválida", code: 400, userInfo: nil))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
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
        
        do {
            let response = try JSONDecoder().decode(DevicesResponse.self, from: data)
            completion(response.devices, nil)
        } catch let decodingError {
            print("❌ Erro na decodificação: \(decodingError)")
            completion(nil, decodingError)
        }
    }.resume()
}

func playTrackOnDevice(deviceId: String, uris: [String]) {
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

// MARK: - Fluxo Principal
func runApplication() {
    print("🚀 Iniciando Terminalfy...")
    
    startAuthentication { success in
        isAuthenticated = success
        
        if success {
            startApplicationFlow()
        } else {
            print("❌ Falha na autenticação. Reinicie o aplicativo.")
            exit(1)
        }
    }
    
    // Mantém o programa rodando enquanto espera por input assíncrono
    dispatchMain()
}
func startApplicationFlow() {
    print("\n🎵 Bem-vindo ao Terminalfy!")
    
    func searchArtist() {
        print("\nDigite o nome do artista que deseja buscar (ou 'sair' para encerrar):")
        guard let artistName = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            searchArtist()
            return
        }
        
        if artistName.lowercased() == "sair" {
            print("👋 Até logo!")
            exit(0)
        }
        
        if artistName.isEmpty {
            print("❌ Nome do artista não pode ser vazio!")
            searchArtist()
            return
        }
        
        print("\n🔍 Buscando artista: \(artistName)...")
        
        searchArtistByName(artistName) { id, name, error in
            if let error = error {
                print("Erro: \(error.localizedDescription)")
                searchArtist()
                return
            }
            
            guard let id = id, let name = name else {
                print("Artista não encontrado.")
                searchArtist()
                return
            }
            
            print("\n✅ Artista encontrado!")
            print("Nome: \(name)")
            print("ID: \(id)")
            
            fetchArtistAlbums(id) { albums, error in
                if let error = error {
                    print("Erro ao buscar álbuns: \(error.localizedDescription)")
                    searchArtist()
                    return
                }
                
                guard let albums = albums, !albums.isEmpty else {
                    print("Nenhum álbum encontrado.")
                    searchArtist()
                    return
                }
                
                print("\nÁlbuns encontrados:")
                for (index, album) in albums.enumerated() {
                    displayAlbum(album, index: index)
                }
                
                print("\nQual álbum você deseja escutar? (Digite o número ou 'voltar'):")
                guard let input = readLine() else {
                    searchArtist()
                    return
                }
                
                if input.lowercased() == "voltar" {
                    searchArtist()
                    return
                }
                
                guard let index = Int(input), index > 0, index <= albums.count else {
                    print("❌ Número inválido")
                    searchArtist()
                    return
                }
                
                let selectedAlbum = albums[index - 1]
                print("\n🎶 Preparando para tocar o álbum \(selectedAlbum.name)...")
                
                fetchAlbumTracks(selectedAlbum.id) { tracks, error in
                    if let error = error {
                        print("❌ Erro ao buscar músicas: \(error.localizedDescription)")
                        searchArtist()
                        return
                    }
                    
                    guard let tracks = tracks, !tracks.isEmpty else {
                        print("⚠️ Nenhuma música encontrada para o álbum.")
                        searchArtist()
                        return
                    }
                    
                    displayTracks(tracks, from: selectedAlbum)
                    
                    print("\nSelecione a música que deseja tocar (Digite o número ou 'voltar'):")
                    guard let trackInput = readLine() else {
                        searchArtist()
                        return
                    }
                    
                    if trackInput.lowercased() == "voltar" {
                        searchArtist()
                        return
                    }
                    
                    guard let trackIndex = Int(trackInput), trackIndex > 0, trackIndex <= tracks.count else {
                        print("❌ Número inválido")
                        searchArtist()
                        return
                    }
                    
                    let selectedTrack = tracks[trackIndex - 1]
                    print("\nPreparando para tocar a música \(selectedTrack.name)")
                    
                    getAvailableDevices { devices, error in
                        if let error = error {
                            print("\n❌ Erro ao buscar dispositivos: \(error.localizedDescription)")
                            searchArtist()
                            return
                        }
                        
                        guard let devices = devices, !devices.isEmpty else {
                            print("\n⚠️ Nenhum dispositivo do Spotify encontrado.")
                            print("Certifique-se que o Spotify está aberto em algum dispositivo (app desktop, web ou mobile)")
                            searchArtist()
                            return
                        }
                        
                        print("\n✅ Dispositivos encontrados:")
                        for (index, device) in devices.enumerated() {
                            print("\n\(index + 1). \(device.name)")
                            print("   🔹 ID: \(device.id ?? "N/A")")
                            print("   🔹 Status: \(device.is_active ? "Ativo" : "Inativo")")
                        }
                        
                        print("\nEm qual dispositivo você deseja tocar a música? (Digite o número ou 'voltar'):")
                        guard let deviceInput = readLine() else {
                            searchArtist()
                            return
                        }
                        
                        if deviceInput.lowercased() == "voltar" {
                            searchArtist()
                            return
                        }
                        
                        guard let deviceIndex = Int(deviceInput), deviceIndex > 0, deviceIndex <= devices.count else {
                            print("❌ Número inválido")
                            searchArtist()
                            return
                        }
                        
                        let selectedDevice = devices[deviceIndex - 1]
                        playTrackOnDevice(deviceId: selectedDevice.id ?? "", uris: [selectedTrack.uri])
                        searchArtist()
                    }
                }
            }
        }
    }
    
    // Inicia o fluxo
    searchArtist()
}

// Inicia a aplicação
runApplication()
