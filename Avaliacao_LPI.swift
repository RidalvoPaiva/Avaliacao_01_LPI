import Foundation

// MARK: - Dicionário de dados conforme especificação do professor
// Chave: String (nome da pessoa)
// Valor: Array [email, telefone, idade]
var pessoas: [String: [String]] = [:]

// MARK: - Cores ANSI para terminal
enum Cor {
    static let reset = "\u{001B}[0m"
    static let vermelho = "\u{001B}[31m"
    static let verde = "\u{001B}[32m"
    static let amarelo = "\u{001B}[33m"
    static let azul = "\u{001B}[34m"
    static let magenta = "\u{001B}[35m"
    static let ciano = "\u{001B}[36m"
    static let branco = "\u{001B}[37m"
    static let bold = "\u{001B}[1m"
    
    static func aplicar(_ texto: String, cor: String) -> String {
        return cor + texto + reset
    }
}

// MARK: - Utilitários de Console
enum Console {
    static func readTrimmedLine(prompt: String = "") -> String? {
        if !prompt.isEmpty { print(prompt, terminator: "") }
        guard let line = readLine() else { return nil }
        return line.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static func readNonEmpty(prompt: String) -> String {
        while true {
            if let text = readTrimmedLine(prompt: prompt), !text.isEmpty {
                return text
            }
            print(Cor.aplicar("✗ Valor obrigatório. Tente novamente.", cor: Cor.vermelho))
        }
    }
    
    static func readPositiveInt(prompt: String) -> String {
        while true {
            let text = readNonEmpty(prompt: prompt)
            if let val = Int(text), val > 0 {
                return text // Retorna como String para armazenar
            }
            print(Cor.aplicar("✗ Insira um número inteiro positivo.", cor: Cor.vermelho))
        }
    }
    
    static func confirm(prompt: String) -> Bool {
        while true {
            if let resp = readTrimmedLine(prompt: prompt)?.uppercased() {
                if resp == "S" { return true }
                if resp == "N" { return false }
            }
            print("Digite 'S' para Sim ou 'N' para Não.")
        }
    }
    
    static func waitEnter(message: String = "\nTecle ENTER para continuar...") {
        print(Cor.aplicar(message, cor: Cor.ciano))
        _ = readLine()
    }
    
    static func limparTela() {
        print(String(repeating: "\n", count: 2))
    }
}

// MARK: - Validações
struct Validacao {
    static func emailValido(_ email: String) -> Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }
    
    static func normalizarNome(_ nome: String) -> String {
        return nome.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    static func celularNormalizado(_ celular: String) -> String {
        let allowed = CharacterSet(charactersIn: "+0123456789")
        return String(celular.unicodeScalars.filter { allowed.contains($0) })
    }
    
    static func celularValido(_ celular: String) -> Bool {
        let normalizado = celularNormalizado(celular)
        // Remove o símbolo de + para contar apenas dígitos
        let somenteNumeros = normalizado.replacingOccurrences(of: "+", with: "")
        
        // Validação:
        // Mínimo 10 dígitos (DDD + 8 dígitos antigo) ou 11 dígitos (DDD + 9 dígitos novo)
        // Máximo 13 dígitos (com código do país +55)
        let qtdDigitos = somenteNumeros.count
        
        // Deve ter entre 10 e 13 dígitos
        if qtdDigitos < 10 || qtdDigitos > 13 {
            return false
        }
        
        // Se tiver exatamente 10 ou 11 dígitos (sem código de país)
        if qtdDigitos == 10 || qtdDigitos == 11 {
            return true
        }
        
        // Se tiver 12 ou 13 dígitos, deve começar com 55 (código do Brasil)
        if (qtdDigitos == 12 || qtdDigitos == 13) && somenteNumeros.hasPrefix("55") {
            return true
        }
        
        return false
    }
    
    static func nomeExiste(_ nome: String) -> Bool {
        let chave = normalizarNome(nome)
        return pessoas.keys.contains { normalizarNome($0) == chave }
    }
    
    static func buscarPorFragmento(_ fragmento: String) -> [String] {
        let frag = normalizarNome(fragmento)
        return pessoas.keys.filter { normalizarNome($0).contains(frag) }
    }
    
    static func encontrarNomeExato(_ nome: String) -> String? {
        let chave = normalizarNome(nome)
        return pessoas.keys.first { normalizarNome($0) == chave }
    }
}

// MARK: - Persistência de Dados
struct BancoDeDados {
    static let nomeArquivo = "pessoas.json"
    
    static func salvar() {
        do {
            let dados = try JSONSerialization.data(withJSONObject: pessoas, options: .prettyPrinted)
            let url = URL(fileURLWithPath: nomeArquivo)
            try dados.write(to: url)
        } catch {
            print(Cor.aplicar("Erro ao salvar dados: \(error)", cor: Cor.vermelho))
        }
    }
    
    static func carregar() {
        let url = URL(fileURLWithPath: nomeArquivo)
        
        guard FileManager.default.fileExists(atPath: nomeArquivo) else {
            return // Primeira execução
        }
        
        do {
            let dados = try Data(contentsOf: url)
            if let dadosCarregados = try JSONSerialization.jsonObject(with: dados) as? [String: [String]] {
                pessoas = dadosCarregados
                print(Cor.aplicar("✓ \(pessoas.count) pessoa(s) carregada(s) do banco de dados", cor: Cor.verde))
            }
        } catch {
            print(Cor.aplicar("Erro ao carregar dados: \(error)", cor: Cor.vermelho))
        }
    }
}

// MARK: - Visualização em Tabela Profissional
struct TabelaProfissional {
    // Função auxiliar para aplicar padding SEM contar códigos de cor
    static func pad(_ texto: String, tamanho: Int) -> String {
        let espacos = tamanho - texto.count
        return texto + String(repeating: " ", count: max(0, espacos))
    }
    
    static func exibir(_ dados: [(nome: String, info: [String])]) {
        guard !dados.isEmpty else { return }
        
        // Calcular larguras dinâmicas baseadas no conteúdo REAL (sem cores)
        let nomeWidth = max(15, dados.map { $0.nome.count }.max() ?? 0)
        let emailWidth = max(25, dados.map { $0.info[0].count }.max() ?? 0)
        let celularWidth = max(15, dados.map { $0.info[1].count }.max() ?? 0)
        let idadeWidth = 6
        
        // Calcular largura total corretamente: colunas + separadores
        // 2 (número) + 3 espaços + nomeWidth + 3 + emailWidth + 3 + celularWidth + 3 + idadeWidth + 2
        let larguraTotal = 2 + 3 + nomeWidth + 3 + emailWidth + 3 + celularWidth + 3 + idadeWidth + 2
        
        // Linha divisória
        let linhaDivisoria = String(repeating: "─", count: larguraTotal)
        
        // Cabeçalho
        print(Cor.ciano + "┌" + linhaDivisoria + "┐" + Cor.reset)
        
        let headerNum = pad("#", tamanho: 2)
        let headerNome = pad("Nome", tamanho: nomeWidth)
        let headerEmail = pad("Email", tamanho: emailWidth)
        let headerCelular = pad("Celular", tamanho: celularWidth)
        let headerIdade = pad("Idade", tamanho: idadeWidth)
        
        print(Cor.ciano + "│ " + Cor.reset +
              Cor.bold + headerNum + Cor.reset +
              Cor.ciano + " │ " + Cor.reset +
              Cor.bold + headerNome + Cor.reset +
              Cor.ciano + " │ " + Cor.reset +
              Cor.bold + headerEmail + Cor.reset +
              Cor.ciano + " │ " + Cor.reset +
              Cor.bold + headerCelular + Cor.reset +
              Cor.ciano + " │ " + Cor.reset +
              Cor.bold + headerIdade + Cor.reset +
              Cor.ciano + " │" + Cor.reset)
        
        print(Cor.ciano + "├" + linhaDivisoria + "┤" + Cor.reset)
        
        // Dados
        for (index, item) in dados.enumerated() {
            let num = pad(String(index + 1), tamanho: 2)
            let nome = pad(item.nome, tamanho: nomeWidth)
            let email = pad(item.info[0], tamanho: emailWidth)
            let celular = pad(item.info[1], tamanho: celularWidth)
            let idade = pad(item.info[2], tamanho: idadeWidth)
            
            print(Cor.ciano + "│ " + Cor.reset +
                  Cor.amarelo + num + Cor.reset +
                  Cor.ciano + " │ " + Cor.reset +
                  nome +
                  Cor.ciano + " │ " + Cor.reset +
                  email +
                  Cor.ciano + " │ " + Cor.reset +
                  celular +
                  Cor.ciano + " │ " + Cor.reset +
                  idade +
                  Cor.ciano + " │" + Cor.reset)
        }
        
        print(Cor.ciano + "└" + linhaDivisoria + "┘" + Cor.reset)
    }
}

// MARK: - Funções CRUD
func criar() {
    Console.limparTela()
    print(Cor.aplicar("═══════════════════════════════", cor: Cor.verde))
    print(Cor.aplicar("   CRIAR NOVA PESSOA", cor: Cor.bold + Cor.verde))
    print(Cor.aplicar("═══════════════════════════════\n", cor: Cor.verde))
    
    let nome = Console.readNonEmpty(prompt: "Nome: ")
    
    if Validacao.nomeExiste(nome) {
        print(Cor.aplicar("\n✗ Já existe uma pessoa com esse nome!", cor: Cor.vermelho))
        Console.waitEnter()
        return
    }
    
    var email: String
    while true {
        email = Console.readNonEmpty(prompt: "Email: ")
        if Validacao.emailValido(email) { break }
        print(Cor.aplicar("✗ Email inválido. Ex.: nome@dominio.com", cor: Cor.vermelho))
    }
    
    var celular: String
    while true {
        let celularRaw = Console.readNonEmpty(prompt: "Celular: ")
        if Validacao.celularValido(celularRaw) {
            celular = Validacao.celularNormalizado(celularRaw)
            break
        }
        print(Cor.aplicar("✗ Celular inválido. Digite no mínimo 9 dígitos.", cor: Cor.vermelho))
    }
    
    let idade = Console.readPositiveInt(prompt: "Idade: ")
    
    // Armazenar no dicionário conforme especificação
    pessoas[nome] = [email, celular, idade]
    BancoDeDados.salvar()
    
    print(Cor.aplicar("\n✓ Pessoa cadastrada com sucesso!", cor: Cor.verde))
    Console.waitEnter()
}

func alterar() {
    Console.limparTela()
    print(Cor.aplicar("═══════════════════════════════", cor: Cor.amarelo))
    print(Cor.aplicar("   ALTERAR PESSOA", cor: Cor.bold + Cor.amarelo))
    print(Cor.aplicar("═══════════════════════════════\n", cor: Cor.amarelo))
    
    guard !pessoas.isEmpty else {
        print(Cor.aplicar("Nenhuma pessoa cadastrada.", cor: Cor.vermelho))
        Console.waitEnter()
        return
    }
    
    let termo = Console.readTrimmedLine(prompt: "Nome (ou parte) da pessoa: ") ?? ""
    let matches = Validacao.buscarPorFragmento(termo)
    
    if matches.isEmpty {
        print(Cor.aplicar("✗ Nenhuma correspondência encontrada.", cor: Cor.vermelho))
        Console.waitEnter()
        return
    }
    
    var nomeEscolhido: String
    if matches.count == 1 {
        nomeEscolhido = matches[0]
    } else {
        print(Cor.aplicar("\nForam encontradas \(matches.count) correspondências:\n", cor: Cor.amarelo))
        let dados = matches.sorted().map { (nome: $0, info: pessoas[$0]!) }
        TabelaProfissional.exibir(dados)
        
        while true {
            if let escolhaStr = Console.readTrimmedLine(prompt: "\nEscolha o número: "),
               let escolha = Int(escolhaStr),
               escolha >= 1, escolha <= matches.count {
                nomeEscolhido = matches.sorted()[escolha - 1]
                break
            }
            print(Cor.aplicar("Escolha inválida.", cor: Cor.vermelho))
        }
    }
    
    guard let dadosAtuais = pessoas[nomeEscolhido] else { return }
    
    print(Cor.aplicar("\nDados atuais:", cor: Cor.ciano))
    TabelaProfissional.exibir([(nome: nomeEscolhido, info: dadosAtuais)])
    
    print(Cor.aplicar("\n--- Deixe em branco para manter o valor atual ---", cor: Cor.ciano))
    
    var novoNome = nomeEscolhido
    if let temp = Console.readTrimmedLine(prompt: "Novo nome: "), !temp.isEmpty {
        if Validacao.nomeExiste(temp) && Validacao.normalizarNome(temp) != Validacao.normalizarNome(nomeEscolhido) {
            print(Cor.aplicar("✗ Nome já existe. Mantendo o anterior.", cor: Cor.vermelho))
        } else {
            novoNome = temp
        }
    }
    
    var email = dadosAtuais[0]
    if let temp = Console.readTrimmedLine(prompt: "Novo email: "), !temp.isEmpty {
        if Validacao.emailValido(temp) {
            email = temp
        } else {
            print(Cor.aplicar("✗ Email inválido. Mantendo o anterior.", cor: Cor.vermelho))
        }
    }
    
    var celular = dadosAtuais[1]
    if let temp = Console.readTrimmedLine(prompt: "Novo celular: "), !temp.isEmpty {
        if Validacao.celularValido(temp) {
            celular = Validacao.celularNormalizado(temp)
        } else {
            print(Cor.aplicar("✗ Celular inválido (mínimo 9 dígitos). Mantendo o anterior.", cor: Cor.vermelho))
        }
    }
    
    var idade = dadosAtuais[2]
    if let temp = Console.readTrimmedLine(prompt: "Nova idade: "), !temp.isEmpty {
        if let val = Int(temp), val > 0 {
            idade = temp
        } else {
            print(Cor.aplicar("✗ Idade inválida. Mantendo a anterior.", cor: Cor.vermelho))
        }
    }
    
    // Se o nome mudou, remover a chave antiga
    if novoNome != nomeEscolhido {
        pessoas.removeValue(forKey: nomeEscolhido)
    }
    
    pessoas[novoNome] = [email, celular, idade]
    BancoDeDados.salvar()
    
    print(Cor.aplicar("\n✓ Dados atualizados com sucesso!", cor: Cor.verde))
    Console.waitEnter()
}

func apagar() {
    Console.limparTela()
    print(Cor.aplicar("═══════════════════════════════", cor: Cor.vermelho))
    print(Cor.aplicar("   APAGAR PESSOA", cor: Cor.bold + Cor.vermelho))
    print(Cor.aplicar("═══════════════════════════════\n", cor: Cor.vermelho))
    
    guard !pessoas.isEmpty else {
        print(Cor.aplicar("Nenhuma pessoa cadastrada.", cor: Cor.vermelho))
        Console.waitEnter()
        return
    }
    
    let termo = Console.readTrimmedLine(prompt: "Nome (ou parte) da pessoa: ") ?? ""
    let matches = Validacao.buscarPorFragmento(termo)
    
    if matches.isEmpty {
        print(Cor.aplicar("✗ Nenhuma correspondência encontrada.", cor: Cor.vermelho))
        Console.waitEnter()
        return
    }
    
    var nomeEscolhido: String
    if matches.count == 1 {
        nomeEscolhido = matches[0]
    } else {
        print(Cor.aplicar("\nForam encontradas \(matches.count) correspondências:\n", cor: Cor.amarelo))
        let dados = matches.sorted().map { (nome: $0, info: pessoas[$0]!) }
        TabelaProfissional.exibir(dados)
        
        while true {
            if let escolhaStr = Console.readTrimmedLine(prompt: "\nEscolha o número: "),
               let escolha = Int(escolhaStr),
               escolha >= 1, escolha <= matches.count {
                nomeEscolhido = matches.sorted()[escolha - 1]
                break
            }
            print(Cor.aplicar("Escolha inválida.", cor: Cor.vermelho))
        }
    }
    
    if Console.confirm(prompt: "Tem certeza que deseja apagar '\(nomeEscolhido)'? (S/N): ") {
        pessoas.removeValue(forKey: nomeEscolhido)
        BancoDeDados.salvar()
        print(Cor.aplicar("\n✓ Pessoa apagada com sucesso!", cor: Cor.verde))
    } else {
        print(Cor.aplicar("\n✗ Operação cancelada.", cor: Cor.amarelo))
    }
    Console.waitEnter()
}

func exibirUma() {
    Console.limparTela()
    print(Cor.aplicar("═══════════════════════════════", cor: Cor.azul))
    print(Cor.aplicar("   EXIBIR UMA PESSOA", cor: Cor.bold + Cor.azul))
    print(Cor.aplicar("═══════════════════════════════\n", cor: Cor.azul))
    
    guard !pessoas.isEmpty else {
        print(Cor.aplicar("Nenhuma pessoa cadastrada.", cor: Cor.vermelho))
        Console.waitEnter()
        return
    }
    
    let termo = Console.readTrimmedLine(prompt: "Nome (ou parte): ") ?? ""
    let matches = Validacao.buscarPorFragmento(termo)
    
    if matches.isEmpty {
        print(Cor.aplicar("✗ Nenhuma correspondência encontrada.", cor: Cor.vermelho))
        Console.waitEnter()
        return
    }
    
    var nomeEscolhido: String
    if matches.count == 1 {
        nomeEscolhido = matches[0]
    } else {
        print(Cor.aplicar("\nForam encontradas \(matches.count) correspondências:\n", cor: Cor.amarelo))
        let dados = matches.sorted().map { (nome: $0, info: pessoas[$0]!) }
        TabelaProfissional.exibir(dados)
        
        while true {
            if let escolhaStr = Console.readTrimmedLine(prompt: "\nEscolha o número: "),
               let escolha = Int(escolhaStr),
               escolha >= 1, escolha <= matches.count {
                nomeEscolhido = matches.sorted()[escolha - 1]
                break
            }
            print(Cor.aplicar("Escolha inválida.", cor: Cor.vermelho))
        }
    }
    
    if let info = pessoas[nomeEscolhido] {
        print()
        TabelaProfissional.exibir([(nome: nomeEscolhido, info: info)])
    }
    Console.waitEnter()
}

func exibirTodas() {
    Console.limparTela()
    print(Cor.aplicar("═══════════════════════════════", cor: Cor.magenta))
    print(Cor.aplicar("   TODAS AS PESSOAS", cor: Cor.bold + Cor.magenta))
    print(Cor.aplicar("═══════════════════════════════\n", cor: Cor.magenta))
    
    guard !pessoas.isEmpty else {
        print(Cor.aplicar("Nenhuma pessoa cadastrada.", cor: Cor.vermelho))
        Console.waitEnter()
        return
    }
    
    print(Cor.aplicar("Total: \(pessoas.count) pessoa(s) cadastrada(s)\n", cor: Cor.ciano))
    
    let ordenadas = pessoas.keys.sorted().map { (nome: $0, info: pessoas[$0]!) }
    TabelaProfissional.exibir(ordenadas)
    Console.waitEnter()
}

// MARK: - Menu Principal
func exibirMenu() {
    Console.limparTela()
    
    // Menu sem cores nos textos internos para evitar quebra
    print(Cor.ciano + "╔════════════════════════════════════════╗" + Cor.reset)
    print(Cor.ciano + "║                                        ║" + Cor.reset)
    print(Cor.ciano + "║    " + Cor.reset + Cor.bold + "SISTEMA DE CADASTRO DE PESSOAS" + Cor.reset + Cor.ciano + "    ║" + Cor.reset)
    print(Cor.ciano + "║           " + Cor.reset + Cor.amarelo + "CRUD Completo" + Cor.reset + Cor.ciano + "                 ║" + Cor.reset)
    print(Cor.ciano + "║                                        ║" + Cor.reset)
    print(Cor.ciano + "╚════════════════════════════════════════╝" + Cor.reset)
    print()
    
    print(Cor.verde + "  1" + Cor.reset + " │ Cadastar nova pessoa")
    print(Cor.amarelo + "  2" + Cor.reset + " │ Alterar dados da pessoa")
    print(Cor.vermelho + "  3" + Cor.reset + " │ Apagar dados da pessoa")
    print(Cor.azul + "  4" + Cor.reset + " │ Exibir dados da pessoa")
    print(Cor.magenta + "  5" + Cor.reset + " │ Exibir todas as pessoas cadastradas")
    print(Cor.vermelho + Cor.bold + "  0" + Cor.reset + " │ Sair do sistema")
    print()
    print(Cor.ciano + "────────────────────────────────────────" + Cor.reset)
    print("Escolha uma opção: ", terminator: "")
}

// MARK: - Programa Principal
func main() {
    // Carregar dados salvos
    BancoDeDados.carregar()
    
    var opcao: String
    repeat {
        exibirMenu()
        opcao = Console.readTrimmedLine() ?? ""
        
        switch opcao {
        case "1": criar()
        case "2": alterar()
        case "3": apagar()
        case "4": exibirUma()
        case "5": exibirTodas()
        case "0":
            Console.limparTela()
            print(Cor.aplicar("Encerrando o sistema... Até Breve! 👋", cor: Cor.verde + Cor.bold))
        default:
            print(Cor.aplicar("\n✗ Opção inválida!", cor: Cor.vermelho))
            Console.waitEnter()
        }
    } while opcao != "0"
}

// Executar o programa
main()