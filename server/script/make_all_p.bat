cd ..
erl -pa ebin -noinput -eval "case mmake:all(2,[]) of up_to_date -> halt(0); error -> halt(1) end."
pause