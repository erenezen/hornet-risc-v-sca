# Hornet RISC-V with Side-Channel Analysis (SCA)

Bu proje, RISC-V mimarisi (Hornet core) tabanlı bir işlemci tasarımı ile Side-Channel Analysis (SCA) saldırı yeteneklerini birleştirmektedir. Proje yapısı, Vivado donanım ortamını ve SCA yazılım/ML ortamını kapsamaktadır.

## Proje Dizini

### 1. `project_1/` (Donanım & Test Ortamı)
Vivado FPGA projesine dair her şeyi içerir. 
* Hornet işlemci çekirdeği ve donanım tasarım kodları (Verilog/HDL).
* Davranışsal testbench dosyaları ve test ortamları.
* `project_1.xpr` ana Vivado proje dosyasını barındırır. İşlemci tasarımlarına ve RTL analizine buradan ulaşabilirsiniz.

### 2. `sca/` (Yazılım & Makine Öğrenmesi Kodları)
Side-Channel saldırısı, veri toplama rutinleri ve Makine Öğrenmesi (ML) bölümleri burada bulunur.
* **C Kodları:** SCA hedefleri ve C dilinde yazılmış saldırı kodları (`main.c`, `sca_attack.c`, `aes_sbox`, vb.).
* **ML Modelleri:** Geliştirilen ML modelleri ve veri analizi dosyaları (Jupyter notebook'lar, `.keras` eğitilmiş modeller, .npy numpy dizileri vs.).
* RISC-V donanımına ve simülasyon ortamına atılmak üzere C kodundan derlenen yardımcı programları barındırır.

### 3. `test/` (Ortak Test ve Çeviri Araçları)
Hornet çekirdek testleri ve genel araç derleme klasörü.
* C Runtime rutinleri (`crt0.s`) ve linker yapılandırmaları (`linksc.ld`).
* C programlarını RISC-V makine belleği opcodelarına çeviren `rom_generator.c` aracı.

## Kurulum ve Kullanım
* **Donanım Derlemesi:** `project_1/project_1.xpr` projesini Vivado yazılımında açıp simülasyon ve sentez işlemlerini yürütebilirsiniz.
* **Büyük Dosya Notu:** Sentez sırasında oluşan ara dosyalar, Vivado run ve cache logları, FPGA implementasyon artıkları ve GitHub'ın 100MB üzerine izin vermediği büyük bellek `*.hex` / `*.exe` dosyaları Git üzerinden izlenmemektedir. Depoyu indirirken tüm kodlara doğrudan erişirsiniz.
