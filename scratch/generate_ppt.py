import os
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.enum.shapes import MSO_SHAPE

def create_presentation():
    prs = Presentation()
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)
    blank_layout = prs.slide_layouts[6] # blank layout

    # Color definitions
    C_DARK_NAVY = RGBColor(44, 62, 80)     # #2C3E50
    C_TEAL      = RGBColor(27, 188, 155)   # #1BBC9B (App primary)
    C_LIGHT_BG  = RGBColor(248, 249, 250)  # #F8F9FA
    C_WHITE     = RGBColor(255, 255, 255)
    C_TEXT_DARK = RGBColor(33, 37, 41)     # #212529
    C_TEXT_MUTED= RGBColor(108, 117, 125)  # #6C757D
    C_CARD_BG   = RGBColor(255, 255, 255)
    C_BORDER    = RGBColor(222, 226, 230)
    C_GREEN     = RGBColor(40, 167, 69)
    C_RED       = RGBColor(220, 53, 69)
    C_BLUE      = RGBColor(23, 162, 184)
    C_ACCENT    = RGBColor(243, 156, 18)

    # Image paths
    img1 = r'C:\Users\yoga\.gemini\antigravity\brain\016f4049-5f97-4796-b9ea-a10e5bd7b62d\.user_uploaded\media_1791247449314.png'
    img2 = r'C:\Users\yoga\.gemini\antigravity\brain\016f4049-5f97-4796-b9ea-a10e5bd7b62d\.user_uploaded\media_1791247536311.png'
    img3 = r'C:\Users\yoga\.gemini\antigravity\brain\016f4049-5f97-4796-b9ea-a10e5bd7b62d\.user_uploaded\media_1791247548355.png'
    img4 = r'C:\Users\yoga\.gemini\antigravity\brain\016f4049-5f97-4796-b9ea-a10e5bd7b62d\.user_uploaded\media_1791247582142.png'
    img5 = r'C:\Users\yoga\.gemini\antigravity\brain\016f4049-5f97-4796-b9ea-a10e5bd7b62d\.user_uploaded\media_1791247592687.png'

    def add_header(slide, title, category="TUTORIAL VPLAS MOBILE"):
        # Header banner
        header_box = slide.shapes.add_textbox(Inches(0.8), Inches(0.4), Inches(11.7), Inches(1.1))
        tf = header_box.text_frame
        tf.word_wrap = True
        tf.margin_left = tf.margin_top = tf.margin_right = tf.margin_bottom = 0
        
        p_cat = tf.paragraphs[0]
        p_cat.text = category.upper()
        p_cat.font.size = Pt(11)
        p_cat.font.bold = True
        p_cat.font.color.rgb = C_TEAL
        p_cat.font.name = "Segoe UI"
        
        p_title = tf.add_paragraph()
        p_title.text = title
        p_title.font.size = Pt(22)
        p_title.font.bold = True
        p_title.font.color.rgb = C_DARK_NAVY
        p_title.font.name = "Segoe UI"

    def set_slide_background(slide, color):
        bg = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, Inches(13.333), Inches(7.5))
        bg.fill.solid()
        bg.fill.fore_color.rgb = color
        bg.line.fill.background() # no line

    # ==========================================
    # SLIDE 1: TITLE SLIDE
    # ==========================================
    s1 = prs.slides.add_slide(blank_layout)
    set_slide_background(s1, C_DARK_NAVY)

    # Decorative accent bar
    bar = s1.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(1.2), Inches(1.8), Inches(0.15), Inches(3.8))
    bar.fill.solid()
    bar.fill.fore_color.rgb = C_TEAL
    bar.line.fill.background()

    # Title box
    tbox = s1.shapes.add_textbox(Inches(1.6), Inches(1.7), Inches(10.5), Inches(3.8))
    tf1 = tbox.text_frame
    tf1.word_wrap = True

    p0 = tf1.paragraphs[0]
    p0.text = "PANDUAN & TUTORIAL INTERAKTIF"
    p0.font.size = Pt(14)
    p0.font.bold = True
    p0.font.color.rgb = C_TEAL
    p0.font.name = "Segoe UI"

    p1 = tf1.add_paragraph()
    p1.text = "VPLAS Mobile:\nBelajar Verilog HDL di Smartphone"
    p1.font.size = Pt(36)
    p1.font.bold = True
    p1.font.color.rgb = C_WHITE
    p1.font.name = "Segoe UI"

    p2 = tf1.add_paragraph()
    p2.text = "Praktik Langkah demi Langkah Menyelesaikan Problem 1 (Start) & Problem 2 (Simple Wire)"
    p2.font.size = Pt(16)
    p2.font.color.rgb = RGBColor(189, 195, 199)
    p2.font.name = "Segoe UI"

    # Bottom badge
    badge = s1.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(1.6), Inches(5.6), Inches(6.8), Inches(0.7))
    badge.fill.solid()
    badge.fill.fore_color.rgb = RGBColor(52, 73, 94)
    badge.line.color.rgb = C_TEAL
    badge.line.width = Pt(1.5)
    
    btf = badge.text_frame
    bp = btf.paragraphs[0]
    bp.text = "Adaptasi Mobile Resmi dari PLAS Verilog (Okayama University) • Mode Offline"
    bp.font.size = Pt(12)
    bp.font.color.rgb = C_WHITE
    bp.alignment = PP_ALIGN.CENTER

    # ==========================================
    # SLIDE 2: ALUR BELAJAR (OVERVIEW)
    # ==========================================
    s2 = prs.slides.add_slide(blank_layout)
    set_slide_background(s2, C_LIGHT_BG)
    add_header(s2, "Alur Pembelajaran Interaktif di VPLAS Mobile", "GAMBARAN UMUM METODE BELAJAR")

    steps = [
        ("1. Buka & Pilih Soal", "Buka Problem List dan pilih topik materi (misal: Problem 1 Start).", C_DARK_NAVY),
        ("2. Pahami Teori & Kode", "Pelajari diagram sirkuit dan struktur kode Verilog yang ditampilkan.", C_BLUE),
        ("3. Jawab Pilihan Ganda", "Pilih jawaban secara praktis lewat ChoiceChips 1-tap tanpa keyboard.", C_TEAL),
        ("4. Submit & Evaluasi", "Tekan tombol Answer untuk evaluasi otomatis instan (SHA-256).", C_ACCENT),
        ("5. Cek Nilai & Lanjut", "Lihat akurasi statistik dan tekan Next untuk lanjut ke Problem 2.", C_GREEN),
    ]

    for idx, (title, desc, color) in enumerate(steps):
        left = Inches(1.0 + idx * 2.3)
        top = Inches(2.2)
        card = s2.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, left, top, Inches(2.1), Inches(4.2))
        card.fill.solid()
        card.fill.fore_color.rgb = C_WHITE
        card.line.color.rgb = color
        card.line.width = Pt(2)

        ctf = card.text_frame
        ctf.word_wrap = True
        ctf.margin_top = Inches(0.3)
        ctf.margin_left = ctf.margin_right = Inches(0.2)

        cp1 = ctf.paragraphs[0]
        cp1.text = title
        cp1.font.size = Pt(15)
        cp1.font.bold = True
        cp1.font.color.rgb = color
        cp1.alignment = PP_ALIGN.CENTER

        cp2 = ctf.add_paragraph()
        cp2.text = "\n" + desc
        cp2.font.size = Pt(12)
        cp2.font.color.rgb = C_TEXT_DARK
        cp2.alignment = PP_ALIGN.CENTER

    # ==========================================
    # SLIDE 3: LANGKAH 1 - PROBLEM LIST
    # ==========================================
    s3 = prs.slides.add_slide(blank_layout)
    set_slide_background(s3, C_LIGHT_BG)
    add_header(s3, "Langkah 1: Membuka Aplikasi & Memilih Problem 1", "NAVIGASI UTAMA")

    # Image 1 (Left side)
    s3.shapes.add_picture(img1, Inches(0.8), Inches(1.6), height=Inches(5.4))

    # Right side text card
    rcard = s3.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(4.5), Inches(1.6), Inches(8.0), Inches(5.4))
    rcard.fill.solid()
    rcard.fill.fore_color.rgb = C_WHITE
    rcard.line.color.rgb = C_BORDER
    rcard.line.width = Pt(1)

    rtf = rcard.text_frame
    rtf.word_wrap = True
    rtf.margin_left = rtf.margin_top = rtf.margin_right = rtf.margin_bottom = Inches(0.4)

    rp = rtf.paragraphs[0]
    rp.text = "Fitur Halaman Utama (Problem List):"
    rp.font.size = Pt(18)
    rp.font.bold = True
    rp.font.color.rgb = C_DARK_NAVY

    items_s3 = [
        ("Header Offline VPLAS & Tombol TOP:", "Menandakan sistem bekerja 100% mandiri tanpa koneksi internet. Tombol TOP memudahkan kembali ke baris atas."),
        ("Kartu Progres (Progress Card):", "Memantau capaian belajar secara langsung: jumlah soal yang Completed (selesai sempurna) dan Tried (sedang dicoba)."),
        ("Daftar 22 Topik Bab 1 Verilog:", "Tersusun berurutan dari pengenalan struktur (Start, Simple Wire) hingga gerbang logika dan rangkaian sekuensial."),
        ("Badge Status (Remark):", "Setiap nomor memiliki penanda visual: 'Tried' (kuning) jika sudah pernah dijawab, dan 'Completed' (hijau) jika akurasi 100%."),
        ("Aksi Mahasiswa:", "Ketuk baris nomor 1 'Start' untuk membuka modul pembelajaran pengenalan Verilog pertama.")
    ]

    for title, desc in items_s3:
        p_item = rtf.add_paragraph()
        p_item.text = f"• {title} "
        p_item.font.bold = True
        p_item.font.size = Pt(13)
        p_item.font.color.rgb = C_DARK_NAVY
        
        # Add normal text
        run = p_item.add_run()
        run.text = desc
        run.font.bold = False
        run.font.color.rgb = C_TEXT_DARK

    # ==========================================
    # SLIDE 4: LANGKAH 2 - MEMAHAMI DIAGRAM & KODE
    # ==========================================
    s4 = prs.slides.add_slide(blank_layout)
    set_slide_background(s4, C_LIGHT_BG)
    add_header(s4, "Langkah 2: Memahami Diagram Sirkuit & Anatomi Verilog", "PROBLEM 1: START")

    # Image 2
    s4.shapes.add_picture(img2, Inches(0.8), Inches(1.6), height=Inches(5.4))

    # Right Card
    rcard4 = s4.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(4.5), Inches(1.6), Inches(8.0), Inches(5.4))
    rcard4.fill.solid()
    rcard4.fill.fore_color.rgb = C_WHITE
    rcard4.line.color.rgb = C_BORDER

    rtf4 = rcard4.text_frame
    rtf4.word_wrap = True
    rtf4.margin_left = rtf4.margin_top = rtf4.margin_right = rtf4.margin_bottom = Inches(0.4)

    rp4 = rtf4.paragraphs[0]
    rp4.text = "Konsep Dasar yang Dipelajari pada Problem 1:"
    rp4.font.size = Pt(18)
    rp4.font.bold = True
    rp4.font.color.rgb = C_DARK_NAVY

    items_s4 = [
        ("Diagram Sirkuit (Circuit Diagram):", "Menggambarkan alur sinyal sederhana dari masukan 'a' dialirkan langsung ke keluaran 'b' melalui kawat (wire)."),
        ("Kata Kunci 'module' & 'endmodule':", "Setiap rangkaian logika dalam Verilog selalu diawali dengan kata kunci pembuka 'module' dan diakhiri dengan 'endmodule'."),
        ("Nama Modul ('start'):", "Dideklarasikan tepat setelah kata kunci module: module start(...);"),
        ("Deklarasi Port Input & Output:", "Port 'input a' adalah masukan sinyal dari luar, sedangkan 'output b' adalah keluaran sinyal hasil rangkaian."),
        ("Pernyataan Penugasan 'assign':", "Digunakan untuk deskripsi penugasan logika kontinu (continuous assignment): assign b = a; (nilai 'a' terus mengalir ke 'b')."),
        ("Editor Kode Bersintaks Terang:", "Dilengkapi penyorotan sintaks (syntax highlighting) warna-warni agar kode mudah dibaca.")
    ]

    for title, desc in items_s4:
        p_item = rtf4.add_paragraph()
        p_item.text = f"• {title} "
        p_item.font.bold = True
        p_item.font.size = Pt(12.5)
        p_item.font.color.rgb = C_DARK_NAVY
        
        run = p_item.add_run()
        run.text = desc
        run.font.bold = False
        run.font.color.rgb = C_TEXT_DARK

    # ==========================================
    # SLIDE 5: LANGKAH 3 - MENGISI JAWABAN PILIHAN GANDA
    # ==========================================
    s5 = prs.slides.add_slide(blank_layout)
    set_slide_background(s5, C_LIGHT_BG)
    add_header(s5, "Langkah 3: Menjawab Soal Interaktif (ChoiceChips)", "PENGISIAN JAWABAN")

    # Image 3
    s5.shapes.add_picture(img3, Inches(0.8), Inches(1.6), height=Inches(5.4))

    # Right Card
    rcard5 = s5.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(4.5), Inches(1.6), Inches(8.0), Inches(5.4))
    rcard5.fill.solid()
    rcard5.fill.fore_color.rgb = C_WHITE
    rcard5.line.color.rgb = C_BORDER

    rtf5 = rcard5.text_frame
    rtf5.word_wrap = True
    rtf5.margin_left = rtf5.margin_top = rtf5.margin_right = rtf5.margin_bottom = Inches(0.4)

    rp5 = rtf5.paragraphs[0]
    rp5.text = "Inovasi Pengisian Jawaban Mobile-Friendly:"
    rp5.font.size = Pt(18)
    rp5.font.bold = True
    rp5.font.color.rgb = C_DARK_NAVY

    items_s5 = [
        ("Murni Pilihan Ganda (Tanpa Kotak Teks):", "Mahasiswa tidak perlu repot mengetik huruf manual di keyboard HP yang rentan typo atau menutupi layar."),
        ("1-Tap ChoiceChips Responsif:", "Cukup satu sentuhan pada opsi (A, B, C, atau D) untuk memilih jawaban secara langsung."),
        ("Indikator 'Blank [X]':", "Setiap pertanyaan memetakan konsep isian nomor 1 sampai 6 pada struktur kode Verilog."),
        ("Pertanyaan 1 & 2:", "No 1 menguji identifikasi nama modul ('start'). No 2 menguji kata kunci pembuka modul ('module')."),
        ("Pertanyaan 3 & 4:", "No 3 menguji kata kunci penutup modul ('endmodule'). No 4 menguji port masukan ('a')."),
        ("Pertanyaan 5 & 6:", "No 5 menguji port keluaran ('b'). No 6 menguji kata kunci continuous assignment ('assign').")
    ]

    for title, desc in items_s5:
        p_item = rtf5.add_paragraph()
        p_item.text = f"• {title} "
        p_item.font.bold = True
        p_item.font.size = Pt(12.5)
        p_item.font.color.rgb = C_DARK_NAVY
        
        run = p_item.add_run()
        run.text = desc
        run.font.bold = False
        run.font.color.rgb = C_TEXT_DARK

    # ==========================================
    # SLIDE 6: LANGKAH 4 - SUBMIT & FEEDBACK
    # ==========================================
    s6 = prs.slides.add_slide(blank_layout)
    set_slide_background(s6, C_LIGHT_BG)
    add_header(s6, "Langkah 4: Melakukan Submit & Umpan Balik Visual", "EVALUASI INSTAN")

    # Image 4
    s6.shapes.add_picture(img4, Inches(0.8), Inches(1.6), height=Inches(5.4))

    # Right Card
    rcard6 = s6.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(4.5), Inches(1.6), Inches(8.0), Inches(5.4))
    rcard6.fill.solid()
    rcard6.fill.fore_color.rgb = C_WHITE
    rcard6.line.color.rgb = C_BORDER

    rtf6 = rcard6.text_frame
    rtf6.word_wrap = True
    rtf6.margin_left = rtf6.margin_top = rtf6.margin_right = rtf6.margin_bottom = Inches(0.4)

    rp6 = rtf6.paragraphs[0]
    rp6.text = "Analisis Umpan Balik (Instant Feedback):"
    rp6.font.size = Pt(18)
    rp6.font.bold = True
    rp6.font.color.rgb = C_DARK_NAVY

    items_s6 = [
        ("Tombol Submit '[ Answer ]':", "Tekan tombol hijau Answer di bagian bawah layar untuk mengevaluasi seluruh jawaban secara otomatis."),
        ("Warna Hijau & Ikon Centang (✓):", "Menandakan jawaban BENAR! Pilihan chip dan penanda Selected berubah menjadi hijau toska (misal: No 1 'start', No 2 'module', No 3 'endmodule', No 4 'a')."),
        ("Warna Merah & Ikon Silang (✗):", "Menandakan jawaban SALAH! Pilihan chip dan penanda Selected berubah menjadi merah (misal: No 5 memilih 'x', No 6 memilih 'output')."),
        ("Pembelajaran Mandiri (Self-Correction):", "Mahasiswa dapat langsung menyadari konsep mana yang belum dipahami dan dapat memperbaikinya kembali sebelum berpindah soal."),
        ("Enkripsi SHA-256 Asli PLAS:", "Penilaian dilakukan secara offline menggunakan formula hash standar Universitas Okayama tanpa risiko kebocoran kunci jawaban.")
    ]

    for title, desc in items_s6:
        p_item = rtf6.add_paragraph()
        p_item.text = f"• {title} "
        p_item.font.bold = True
        p_item.font.size = Pt(12.5)
        p_item.font.color.rgb = C_DARK_NAVY
        
        run = p_item.add_run()
        run.text = desc
        run.font.bold = False
        run.font.color.rgb = C_TEXT_DARK

    # ==========================================
    # SLIDE 7: LANGKAH 5 - STATISTIK & NEXT
    # ==========================================
    s7 = prs.slides.add_slide(blank_layout)
    set_slide_background(s7, C_LIGHT_BG)
    add_header(s7, "Langkah 5: Memeriksa Statistik Akurasi & Navigasi", "HASIL & PROGRES")

    # Image 5
    s7.shapes.add_picture(img5, Inches(0.8), Inches(2.2), width=Inches(4.6))

    # Right Card
    rcard7 = s7.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(5.8), Inches(1.6), Inches(6.7), Inches(5.4))
    rcard7.fill.solid()
    rcard7.fill.fore_color.rgb = C_WHITE
    rcard7.line.color.rgb = C_BORDER

    rtf7 = rcard7.text_frame
    rtf7.word_wrap = True
    rtf7.margin_left = rtf7.margin_top = rtf7.margin_right = rtf7.margin_bottom = Inches(0.4)

    rp7 = rtf7.paragraphs[0]
    rp7.text = "Kartu Statistik & Kontrol Pembelajaran:"
    rp7.font.size = Pt(18)
    rp7.font.bold = True
    rp7.font.color.rgb = C_DARK_NAVY

    items_s7 = [
        ("Total number of questions: 6", "Jumlah total butir isian pertanyaan yang harus diselesaikan pada problem ini."),
        ("Number of correct answers: 4", "Jumlah jawaban yang berhasil benar pada percobaan saat ini (4 dari 6)."),
        ("Accuracy rate: 66.67%", "Persentase akurasi pengerjaan. Warna teks mengikuti standar PLAS (<60% merah, 60-99% netral, 100% hijau)."),
        ("Tombol Refresh (Pojok Kanan Atas):", "Ikon panah melingkar di samping tombol TOP untuk mengosongkan kembali seluruh pilihan jawaban jika ingin mencoba ulang dari awal."),
        ("Tombol Navigasi '[ Next > ]':", "Tekan tombol biru gelap Next di pojok kanan bawah untuk langsung melangkah maju ke Problem 2 (Simple Wire).")
    ]

    for title, desc in items_s7:
        p_item = rtf7.add_paragraph()
        p_item.text = f"• {title} "
        p_item.font.bold = True
        p_item.font.size = Pt(13)
        p_item.font.color.rgb = C_DARK_NAVY
        
        run = p_item.add_run()
        run.text = desc
        run.font.bold = False
        run.font.color.rgb = C_TEXT_DARK

    # ==========================================
    # SLIDE 8: LANGKAH 6 - PROBLEM 2 (SIMPLE WIRE)
    # ==========================================
    s8 = prs.slides.add_slide(blank_layout)
    set_slide_background(s8, C_LIGHT_BG)
    add_header(s8, "Langkah 6: Melanjutkan ke Problem 2: Simple Wire", "TRANSISI MATERI")

    # Comparison cards
    # Card 1 (Problem 1)
    c1 = s8.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.8), Inches(1.8), Inches(5.6), Inches(4.8))
    c1.fill.solid()
    c1.fill.fore_color.rgb = C_WHITE
    c1.line.color.rgb = C_TEAL
    c1.line.width = Pt(2)
    tf_c1 = c1.text_frame
    tf_c1.word_wrap = True
    tf_c1.margin_left = tf_c1.margin_right = tf_c1.margin_top = Inches(0.3)

    p_c1_t = tf_c1.paragraphs[0]
    p_c1_t.text = "Problem 1: Start (Fondasi Konsep)"
    p_c1_t.font.size = Pt(17)
    p_c1_t.font.bold = True
    p_c1_t.font.color.rgb = C_TEAL

    p_c1_d = tf_c1.add_paragraph()
    p_c1_d.text = (
        "\n• Tujuan Pembelajaran:\n"
        "  Mengenalkan mahasiswa pada anatomi dasar kode Verilog.\n\n"
        "• Metode Soal:\n"
        "  Pertanyaan konseptual mengidentifikasi nama modul, kata kunci pembuka/penutup, dan deklarasi port.\n\n"
        "• Bentuk Interaksi:\n"
        "  Daftar pertanyaan pilihan ganda (Multiple Choice Questions) di bawah kode."
    )
    p_c1_d.font.size = Pt(13)
    p_c1_d.font.color.rgb = C_TEXT_DARK

    # Card 2 (Problem 2)
    c2 = s8.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(6.9), Inches(1.8), Inches(5.6), Inches(4.8))
    c2.fill.solid()
    c2.fill.fore_color.rgb = C_WHITE
    c2.line.color.rgb = C_DARK_NAVY
    c2.line.width = Pt(2)
    tf_c2 = c2.text_frame
    tf_c2.word_wrap = True
    tf_c2.margin_left = tf_c2.margin_right = tf_c2.margin_top = Inches(0.3)

    p_c2_t = tf_c2.paragraphs[0]
    p_c2_t.text = "Problem 2: Simple Wire (Praktik Menulis Kode)"
    p_c2_t.font.size = Pt(17)
    p_c2_t.font.bold = True
    p_c2_t.font.color.rgb = C_DARK_NAVY

    p_c2_d = tf_c2.add_paragraph()
    p_c2_d.text = (
        "\n• Penerapan Langsung:\n"
        "  Mahasiswa langsung mengisi bagian kode yang rumpang (code blanks) seperti port keluaran dan kata kunci assign.\n\n"
        "• Selektor Dropdown Adaptif:\n"
        "  Terdapat tombol dropdown otomatis di dalam kode: [ reg ▼ ], [ assign ▼ ] dengan teks utuh.\n\n"
        "• Kartu 'Multiple Choice: Code Blanks':\n"
        "  Tersedia pilihan ganda praktis di bawah kode untuk memilih isian kode dengan 1 ketukan."
    )
    p_c2_d.font.size = Pt(13)
    p_c2_d.font.color.rgb = C_TEXT_DARK

    # ==========================================
    # SLIDE 9: RANGKUMAN & KESIMPULAN
    # ==========================================
    s9 = prs.slides.add_slide(blank_layout)
    set_slide_background(s9, C_DARK_NAVY)

    # Center card
    card_sum = s9.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(1.5), Inches(1.0), Inches(10.3), Inches(5.5))
    card_sum.fill.solid()
    card_sum.fill.fore_color.rgb = C_WHITE
    card_sum.line.fill.background()

    tf_sum = card_sum.text_frame
    tf_sum.word_wrap = True
    tf_sum.margin_left = tf_sum.margin_right = tf_sum.margin_top = Inches(0.4)

    p_st = tf_sum.paragraphs[0]
    p_st.text = "Rangkuman 5 Langkah Belajar Efektif di VPLAS Mobile"
    p_st.font.size = Pt(22)
    p_st.font.bold = True
    p_st.font.color.rgb = C_DARK_NAVY
    p_st.alignment = PP_ALIGN.CENTER

    summary_items = [
        "1. Amati Diagram & Kode: Luangkan waktu sejenak memahami arah sinyal dan nama port sebelum menjawab.",
        "2. Manfaatkan ChoiceChips: Ketuk pilihan ganda interaktif tanpa perlu repot mengetik di keyboard HP.",
        "3. Periksa Umpan Balik: Warna hijau (✓) dan merah (✗) langsung menunjukkan tingkat pemahaman Anda.",
        "4. Coba Lagi Kapan Saja: Tombol refresh memungkinkan Anda mengulang hingga mencapai akurasi 100%.",
        "5. Lanjut Bertahap: Gunakan tombol Next untuk melanjutkan dari Problem 1 (Start) ke Problem 2 (Simple Wire)."
    ]

    for item in summary_items:
        p_i = tf_sum.add_paragraph()
        p_i.text = f"\n✔ {item}"
        p_i.font.size = Pt(14)
        p_i.font.color.rgb = C_TEXT_DARK
        p_i.font.name = "Segoe UI"

    output_path = r'd:\APK_AI\VerilogPLAS_2\Tutorial_VPLAS_Mobile.pptx'
    prs.save(output_path)
    print(f"Presentation saved successfully to {output_path}")

if __name__ == '__main__':
    create_presentation()
