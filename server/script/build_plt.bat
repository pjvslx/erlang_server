
::建立PLT(Persistent Lookup Table)

@echo "--------------------------------------------------------"
@echo "开始建立PLT..."
@echo "默认建立PLT的库: kernel stdlib inets compiler erts tools"
@echo "如有需要，自行添加"
@echo "--------------------------------------------------------"

set HOME=%TMP%
dialyzer --build_plt --apps kernel stdlib inets compiler erts tools --output_plt dialyzer.plt

@echo "--------------------------------------------------------"
@echo "已完成,本目录下: dialyzer.plt"
@echo "--------------------------------------------------------"
pause
