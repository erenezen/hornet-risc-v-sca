# ==============================================================================
# Vivado Rebuild Script - Tüm projeyi baştan derler
# ==============================================================================
# Kullanım: Vivado TCL Console'da: source rebuild.tcl
# ==============================================================================

puts "=========================================="
puts "Vivado Proje Rebuild Başlatılıyor..."
puts "=========================================="

# Projeyi aç
if {[file exists project_1.xpr]} {
    open_project project_1.xpr
    puts "✓ Proje açıldı: project_1.xpr"
} else {
    puts "✗ HATA: project_1.xpr bulunamadı!"
    return
}

# Eski run'ları temizle (opsiyonel - yorum satırını kaldırın)
# reset_run synth_1
# reset_run impl_1
# puts "✓ Eski run'lar temizlendi"

# ==============================================================================
# SYNTHESIS
# ==============================================================================
puts "\n=========================================="
puts "1. SYNTHESIS başlatılıyor..."
puts "=========================================="

launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Synthesis sonucunu kontrol et
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "✗ HATA: Synthesis başarısız!"
    return
} else {
    puts "✓ Synthesis başarıyla tamamlandı"
}

# ==============================================================================
# IMPLEMENTATION
# ==============================================================================
puts "\n=========================================="
puts "2. IMPLEMENTATION başlatılıyor..."
puts "=========================================="

launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Implementation sonucunu kontrol et
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "✗ HATA: Implementation başarısız!"
    return
} else {
    puts "✓ Implementation başarıyla tamamlandı"
}

# ==============================================================================
# BITSTREAM GENERATION
# ==============================================================================
puts "\n=========================================="
puts "3. BITSTREAM oluşturuluyor..."
puts "=========================================="

launch_runs impl_1 -jobs 4 -to_step write_bitstream
wait_on_run impl_1

# Bitstream kontrolü
set bitstream_file "project_1.runs/impl_1/fpga_top.bit"
if {[file exists $bitstream_file]} {
    puts "✓ Bitstream oluşturuldu: $bitstream_file"
} else {
    puts "✗ HATA: Bitstream dosyası bulunamadı!"
    return
}

# ==============================================================================
# RAPORLAR (Opsiyonel)
# ==============================================================================
puts "\n=========================================="
puts "4. Raporlar oluşturuluyor..."
puts "=========================================="

open_run impl_1

# Timing raporu
report_timing_summary -file "project_1.runs/impl_1/timing_summary.rpt" -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10
puts "✓ Timing raporu: project_1.runs/impl_1/timing_summary.rpt"

# Utilization raporu
report_utilization -file "project_1.runs/impl_1/utilization.rpt" -hierarchical
puts "✓ Utilization raporu: project_1.runs/impl_1/utilization.rpt"

# ==============================================================================
# ÖZET
# ==============================================================================
puts "\n=========================================="
puts "✓✓✓ REBUILD TAMAMLANDI ✓✓✓"
puts "=========================================="
puts "Bitstream konumu:"
puts "  $bitstream_file"
puts "\nSonraki adım: FPGA'ya yüklemek için"
puts "  Open Hardware Manager → Program Device"
puts "=========================================="

