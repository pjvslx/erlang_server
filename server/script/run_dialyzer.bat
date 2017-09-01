
::Dialyzer分析脚本

@echo "--------------------------------------------------------"
@echo "开始Dialyzer分析..."
@echo "默认分析目录 src"
@echo "默认Include目录 include include/protocol"
@echo "--------------------------------------------------------"

set HOME=%TMP%
dialyzer --plt dialyzer.plt --src -I include -I include/protocol -r src/ -o src.dialyzer.txt

@echo "--------------------------------------------------------"
@echo "已完成,本目录下: dialyzer.plt"
@echo "--------------------------------------------------------"
pause
