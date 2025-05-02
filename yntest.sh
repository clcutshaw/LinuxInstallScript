while true; do

read -p Do you wish to proceed? yn

case "$yn" in
  [yY]) echo "Proceeding";
  break;;
  [nN]) echo "Understood, Exiting";
  rm -- $0
  exit;;
  *) echo "Invalid Response";;
esac

done
