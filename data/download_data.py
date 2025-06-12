from playwright.sync_api import sync_playwright
import json
import time
import re

BASE_URL = "https://www.liriocatolico.com.br/biblia_online/biblia_matos_soares/{book_slug}/completo.html"

def get_verses(page, book_slug, num_chapters):
    url = BASE_URL.format(book_slug=book_slug)
    page.goto(url)
    # Extrai o texto do corpo da página, removendo o menu inferior
    content = page.inner_text("body").split("Instruções para leitura e navegação\n")[1].split("\n\nIr para o capítulo:")[0]
    return {
        "book_slug": book_slug,
        "num_chapters": num_chapters,
        "text": content.strip()
    }

books = [
    ("Gênesis", "genesis", 50),
    ("Êxodo", "exodo", 40),
    ("Levítico", "levitico", 27),
    ("Números", "numeros", 36),
    ("Deuteronômio", "deuteronomio", 34),
    ("Josué", "josue", 24),
    ("Juízes", "juizes", 21),
    ("Rute", "rute", 4),
    ("I Samuel", "i-samuel", 31),
    ("II Samuel", "ii-samuel", 24),
    ("I Reis", "i-reis", 22),
    ("II Reis", "ii-reis", 25),
    ("I Crônicas", "i-cronicas", 29),
    ("II Crônicas", "ii-cronicas", 36),
    ("Esdras", "esdras", 10),
    ("Neemias", "neemias", 13),
    ("Tobias", "tobias", 14),
    ("Judite", "judite", 16),
    ("Ester", "ester", 16),
    ("Jó", "jo", 42),
    ("Salmos", "salmos", 150),
    ("I Macabeus", "i-macabeus", 16),
    ("II Macabeus", "ii-macabeus", 15),
    ("Provérbios", "proverbios", 31),
    ("Eclesiastes", "eclesiastes", 12),
    ("Cântico dos Cânticos", "cantico-dos-canticos", 8),
    ("Sabedoria", "sabedoria", 19),
    ("Eclesiástico", "eclesiastico", 51),
    ("Isaías", "isaias", 66),
    ("Jeremias", "jeremias", 52),
    ("Lamentações", "lamentacoes", 5),
    ("Baruc", "baruc", 6),
    ("Ezequiel", "ezequiel", 48),
    ("Daniel", "daniel", 14),
    ("Oséias", "oseias", 14),
    ("Joel", "joel", 3),
    ("Amós", "amos", 9),
    ("Abdias", "abdias", 1),
    ("Jonas", "jonas", 4),
    ("Miquéias", "miqueias", 7),
    ("Naum", "naum", 3),
    ("Habacuc", "habacuc", 3),
    ("Sofonias", "sofonias", 3),
    ("Ageu", "ageu", 2),
    ("Zacarias", "zacarias", 14),
    ("Malaquias", "malaquias", 3),
    ("São Mateus", "sao-mateus", 28),
    ("São Marcos", "sao-marcos", 16),
    ("São Lucas", "sao-lucas", 24),
    ("São João", "sao-joao", 21),
    ("Atos dos Apóstolos", "atos-dos-apostolos", 28),
    ("Romanos", "romanos", 16),
    ("I Coríntios", "i-corintios", 16),
    ("II Coríntios", "ii-corintios", 13),
    ("Gálatas", "galatas", 6),
    ("Efésios", "efesios", 6),
    ("Filipenses", "filipenses", 4),
    ("Colossenses", "colossenses", 4),
    ("I Tessalonicenses", "i-tessalonicenses", 5),
    ("II Tessalonicenses", "ii-tessalonicenses", 3),
    ("I Timóteo", "i-timoteo", 6),
    ("II Timóteo", "ii-timoteo", 4),
    ("Tito", "tito", 3),
    ("Filêmon", "filemon", 1),
    ("Hebreus", "hebreus", 13),
    ("São Tiago", "sao-tiago", 5),
    ("I São Pedro", "i-sao-pedro", 5),
    ("II São Pedro", "ii-sao-pedro", 3),
    ("I São João", "i-sao-joao", 5),
    ("II São João", "ii-sao-joao", 1),
    ("III São João", "iii-sao-joao", 1),
    ("São Judas", "sao-judas", 1),
    ("Apocalipse", "apocalipse", 22),
]

output = []

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)  # headless=True pra não abrir a janela
    page = browser.new_page()

    for book, slug, num_chapters in books:
        print(f"Coletando {book} ({slug}), {num_chapters} capítulos")
        try:
            verse_data = get_verses(page, slug, num_chapters)
            output.append(verse_data)
            print(f" - {book} coletado")
            time.sleep(10)  # Pequena pausa para evitar bloqueio por requisições rápidas
        except Exception as e:
            print(f"Erro ao coletar {book}: {e}")

    browser.close()

with open("biblia_matos_soares_1956.json", "w", encoding="utf-8") as f:
    json.dump(output, f, ensure_ascii=False, indent=2)


def separar_capitulos(texto):
    # Dividir os capítulos com base em "Capítulo X"
    capitulos = re.split(r'Capítulo\s+\d+\s*Ver capítulo\s*', texto)
    # A primeira parte antes do primeiro "Capítulo X" será vazia ou inútil
    capitulos = [c.strip() for c in capitulos if c.strip()]
    return capitulos

with open("biblia_matos_soares_1956.json", "r", encoding="utf-8") as f:
    livros = json.load(f)

novos_livros = []

for livro in livros:
    capitulos = separar_capitulos(livro["text"])
    
    # Verificação opcional de integridade
    if len(capitulos) != livro["num_chapters"]:
        print(f"Aviso: {livro['book_slug']} esperava {livro['num_chapters']} capítulos, mas encontrou {len(capitulos)}")

    novos_livros.append({
        "book_slug": livro["book_slug"],
        "num_chapters": livro["num_chapters"],
        "text": capitulos
    })

with open("biblia_matos_soares_1956_capitulos.json", "w", encoding="utf-8") as f:
    json.dump(novos_livros, f, ensure_ascii=False, indent=2)

def separar_versiculos(texto_capitulo):
    versiculos = []
    matches = list(re.finditer(r'(\d+)\s+(.*?)(?=(\n\n\d+\s)|$)', texto_capitulo, re.DOTALL))

    for match in matches:
        numero = int(match.group(1))
        conteudo = match.group(2).strip().replace('\n', ' ')
        versiculos.append({
            "verse": numero,
            "text": conteudo
        })

    return versiculos

# Load previously split chapters
with open("biblia_matos_soares_1956_capitulos.json", "r", encoding="utf-8") as f:
    livros = json.load(f)

livros_com_versiculos = []

for livro in livros:
    capitulos_com_versiculos = []

    for capitulo in livro["text"]:
        versiculos = separar_versiculos(capitulo)
        capitulos_com_versiculos.append(versiculos)

    livros_com_versiculos.append({
        "book_slug": livro["book_slug"],
        "num_chapters": livro["num_chapters"],
        "chapters": capitulos_com_versiculos
    })

# Save new JSON with verses
with open("biblia_matos_soares_1956_versiculos.json", "w", encoding="utf-8") as f:
    json.dump(livros_com_versiculos, f, ensure_ascii=False, indent=2)