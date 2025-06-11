import SwiftUI

struct ContentView: View {
    @State private var selectedBook = "Gênesis"
    @State private var selectedChapter = 1
    // Header is always visible now
    
    // Sample books for demonstration
    let books = [
        "Gênesis", "Êxodo", "Levítico", "Números", "Deuteronômio",
        "Josué", "Juízes", "Rute", "1 Samuel", "2 Samuel",
        "1 Reis", "2 Reis", "1 Crônicas", "2 Crônicas", "Esdras",
        "Neemias", "Tobias", "Judite", "Ester", "Jó",
        "Salmos", "Provérbios", "Eclesiastes", "Cântico dos Cânticos", "Sabedoria",
        "Eclesiástico", "Isaías", "Jeremias", "Lamentações", "Baruc",
        "Ezequiel", "Daniel", "Oséias", "Joel", "Amós",
        "Abdias", "Jonas", "Miquéias", "Naum", "Habacuc",
        "Sofonias", "Ageu", "Zacarias", "Malaquias",
        "Mateus", "Marcos", "Lucas", "João", "Atos",
        "Romanos", "1 Coríntios", "2 Coríntios", "Gálatas", "Efésios",
        "Filipenses", "Colossenses", "1 Tessalonicenses", "2 Tessalonicenses", "1 Timóteo",
        "2 Timóteo", "Tito", "Filêmon", "Hebreus", "Tiago",
        "1 Pedro", "2 Pedro", "1 João", "2 João", "3 João",
        "Judas", "Apocalipse"
    ]
    
    // Sample verses for demonstration (Genesis 1)
    let sampleVerses = [
        "No princípio criou Deus os céus e a terra.",
        "E a terra era sem forma e vazia; e havia trevas sobre a face do abismo; e o Espírito de Deus se movia sobre a face das águas.",
        "E disse Deus: Haja luz; e houve luz.",
        "E viu Deus que era boa a luz; e fez Deus separação entre a luz e as trevas.",
        "E Deus chamou à luz Dia; e às trevas chamou Noite. E foi a tarde e a manhã, o dia primeiro.",
        "E disse Deus: Haja uma expansão no meio das águas, e haja separação entre águas e águas.",
        "E fez Deus a expansão, e fez separação entre as águas que estavam debaixo da expansão e as águas que estavam sobre a expansão; e assim foi.",
        "E chamou Deus à expansão Céus, e foi a tarde e a manhã, o dia segundo.",
        "E disse Deus: Ajuntem-se as águas debaixo dos céus num lugar; e apareça a porção seca; e assim foi.",
        "No princípio criou Deus os céus e a terra.",
        "E a terra era sem forma e vazia; e havia trevas sobre a face do abismo; e o Espírito de Deus se movia sobre a face das águas.",
        "E disse Deus: Haja luz; e houve luz.",
        "E viu Deus que era boa a luz; e fez Deus separação entre a luz e as trevas.",
        "E Deus chamou à luz Dia; e às trevas chamou Noite. E foi a tarde e a manhã, o dia primeiro.",
        "E disse Deus: Haja uma expansão no meio das águas, e haja separação entre águas e águas.",
        "E fez Deus a expansão, e fez separação entre as águas que estavam debaixo da expansão e as águas que estavam sobre a expansão; e assim foi.",
        "E chamou Deus à expansão Céus, e foi a tarde e a manhã, o dia segundo.",
        "E disse Deus: Ajuntem-se as águas debaixo dos céus num lugar; e apareça a porção seca; e assim foi.",
        "No princípio criou Deus os céus e a terra.",
        "E a terra era sem forma e vazia; e havia trevas sobre a face do abismo; e o Espírito de Deus se movia sobre a face das águas.",
        "E disse Deus: Haja luz; e houve luz.",
        "E viu Deus que era boa a luz; e fez Deus separação entre a luz e as trevas.",
        "E Deus chamou à luz Dia; e às trevas chamou Noite. E foi a tarde e a manhã, o dia primeiro.",
        "E disse Deus: Haja uma expansão no meio das águas, e haja separação entre águas e águas.",
        "E fez Deus a expansão, e fez separação entre as águas que estavam debaixo da expansão e as águas que estavam sobre a expansão; e assim foi.",
        "E chamou Deus à expansão Céus, e foi a tarde e a manhã, o dia segundo.",
        "E disse Deus: Ajuntem-se as águas debaixo dos céus num lugar; e apareça a porção seca; e assim foi.",
        "No princípio criou Deus os céus e a terra.",
        "E a terra era sem forma e vazia; e havia trevas sobre a face do abismo; e o Espírito de Deus se movia sobre a face das águas.",
        "E disse Deus: Haja luz; e houve luz.",
        "E viu Deus que era boa a luz; e fez Deus separação entre a luz e as trevas.",
        "E Deus chamou à luz Dia; e às trevas chamou Noite. E foi a tarde e a manhã, o dia primeiro.",
        "E disse Deus: Haja uma expansão no meio das águas, e haja separação entre águas e águas.",
        "E fez Deus a expansão, e fez separação entre as águas que estavam debaixo da expansão e as águas que estavam sobre a expansão; e assim foi.",
        "E chamou Deus à expansão Céus, e foi a tarde e a manhã, o dia segundo.",
        "E disse Deus: Ajuntem-se as águas debaixo dos céus num lugar; e apareça a porção seca; e assim foi.",
        "No princípio criou Deus os céus e a terra.",
        "E a terra era sem forma e vazia; e havia trevas sobre a face do abismo; e o Espírito de Deus se movia sobre a face das águas.",
        "E disse Deus: Haja luz; e houve luz.",
        "E viu Deus que era boa a luz; e fez Deus separação entre a luz e as trevas.",
        "E Deus chamou à luz Dia; e às trevas chamou Noite. E foi a tarde e a manhã, o dia primeiro.",
        "E disse Deus: Haja uma expansão no meio das águas, e haja separação entre águas e águas.",
        "E fez Deus a expansão, e fez separação entre as águas que estavam debaixo da expansão e as águas que estavam sobre a expansão; e assim foi.",
        "E chamou Deus à expansão Céus, e foi a tarde e a manhã, o dia segundo.",
        "E disse Deus: Ajuntem-se as águas debaixo dos céus num lugar; e apareça a porção seca; e assim foi.",
        "No princípio criou Deus os céus e a terra.",
        "E a terra era sem forma e vazia; e havia trevas sobre a face do abismo; e o Espírito de Deus se movia sobre a face das águas.",
        "E disse Deus: Haja luz; e houve luz.",
        "E viu Deus que era boa a luz; e fez Deus separação entre a luz e as trevas.",
        "E Deus chamou à luz Dia; e às trevas chamou Noite. E foi a tarde e a manhã, o dia primeiro.",
        "E disse Deus: Haja uma expansão no meio das águas, e haja separação entre águas e águas.",
        "E fez Deus a expansão, e fez separação entre as águas que estavam debaixo da expansão e as águas que estavam sobre a expansão; e assim foi.",
        "E chamou Deus à expansão Céus, e foi a tarde e a manhã, o dia segundo.",
        "E disse Deus: Ajuntem-se as águas debaixo dos céus num lugar; e apareça a porção seca; e assim foi.",
        "No princípio criou Deus os céus e a terra.",
        "E a terra era sem forma e vazia; e havia trevas sobre a face do abismo; e o Espírito de Deus se movia sobre a face das águas.",
        "E disse Deus: Haja luz; e houve luz.",
        "E viu Deus que era boa a luz; e fez Deus separação entre a luz e as trevas.",
        "E Deus chamou à luz Dia; e às trevas chamou Noite. E foi a tarde e a manhã, o dia primeiro.",
        "E disse Deus: Haja uma expansão no meio das águas, e haja separação entre águas e águas.",
        "E fez Deus a expansão, e fez separação entre as águas que estavam debaixo da expansão e as águas que estavam sobre a expansão; e assim foi.",
        "E chamou Deus à expansão Céus, e foi a tarde e a manhã, o dia segundo.",
        "E disse Deus: Ajuntem-se as águas debaixo dos céus num lugar; e apareça a porção seca; e assim foi.",
        "No princípio criou Deus os céus e a terra.",
        "E a terra era sem forma e vazia; e havia trevas sobre a face do abismo; e o Espírito de Deus se movia sobre a face das águas.",
        "E disse Deus: Haja luz; e houve luz.",
        "E viu Deus que era boa a luz; e fez Deus separação entre a luz e as trevas.",
        "E Deus chamou à luz Dia; e às trevas chamou Noite. E foi a tarde e a manhã, o dia primeiro.",
        "E disse Deus: Haja uma expansão no meio das águas, e haja separação entre águas e águas.",
        "E fez Deus a expansão, e fez separação entre as águas que estavam debaixo da expansão e as águas que estavam sobre a expansão; e assim foi.",
        "E chamou Deus à expansão Céus, e foi a tarde e a manhã, o dia segundo.",
        "E disse Deus: Ajuntem-se as águas debaixo dos céus num lugar; e apareça a porção seca; e assim foi.",
        "No princípio criou Deus os céus e a terra.",
        "E a terra era sem forma e vazia; e havia trevas sobre a face do abismo; e o Espírito de Deus se movia sobre a face das águas.",
        "E disse Deus: Haja luz; e houve luz.",
        "E viu Deus que era boa a luz; e fez Deus separação entre a luz e as trevas.",
        "E Deus chamou à luz Dia; e às trevas chamou Noite. E foi a tarde e a manhã, o dia primeiro.",
        "E disse Deus: Haja uma expansão no meio das águas, e haja separação entre águas e águas.",
        "E fez Deus a expansão, e fez separação entre as águas que estavam debaixo da expansão e as águas que estavam sobre a expansão; e assim foi.",
        "E chamou Deus à expansão Céus, e foi a tarde e a manhã, o dia segundo.",
        "E disse Deus: Ajuntem-se as águas debaixo dos céus num lugar; e apareça a porção seca; e assim foi.",
        "E chamou Deus à porção seca Terra; e ao ajuntamento das águas chamou Mares; e viu Deus que era bom."
    ]
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with book and chapter pickers
                headerView
                
                // Bible text
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            ForEach(Array(sampleVerses.enumerated()), id: \.offset) { index, verse in
                                HStack(alignment: .top, spacing: 12) {
                                    // Verse number
                                    Text("\(index + 1)")
                                        .font(.system(size: 20, weight: .medium, design: .serif))
                                        .foregroundColor(.secondary)
                                        .frame(width: 25, alignment: .leading)
                                    
                                    // Verse text
                                    Text(verse)
                                        .font(.system(size: 26, weight: .regular, design: .serif))
                                        .foregroundColor(.primary)
                                        .lineSpacing(4)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.horizontal, 20)
                                .id(index)
                            }
                            
                            // Bottom padding for comfortable reading
                            Color.clear
                                .frame(height: 100)
                        }
                        .padding(.top, 20)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                // Book picker
                Menu {
                    ForEach(books, id: \.self) { book in
                        Button(book) {
                            selectedBook = book
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedBook)
                            .font(.system(size: 17, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
                
                // Chapter picker
                Menu {
                    ForEach(1...50, id: \.self) { chapter in
                        Button("Capítulo \(chapter)") {
                            selectedChapter = chapter
                        }
                    }
                } label: {
                    HStack {
                        Text("Cap. \(selectedChapter)")
                            .font(.system(size: 17, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 15)
            .background(
                Color.black
                    .overlay(
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 1),
                        alignment: .bottom
                    )
            )
        }
    }
}

#Preview {
    ContentView()
}
