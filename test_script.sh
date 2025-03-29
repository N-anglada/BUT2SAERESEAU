#!/bin/bash
PASS_COUNT=0
FAIL_COUNT=0


function test_ping() {
  echo -n "[$1 -> ping $2] attendu : $3 ... "
  #c1 -> envoie 1 paquet / W1 -> attend 1 seucond /
  #2>&1 pour meme prendre les messages d'erreur dans output
  output=$(kathara exec $1 -- ping -c1 -W1 $2 2>&1)
  #-q pour ne pas afficher dans la console la ligne
  if echo "$output" | grep -q "1 received"; then
    GREP_RET=0
  else
    GREP_RET=1
  fi
  if [[ "$3" == "ALLOW" && "$GREP_RET" -eq 0 ]]; then
    echo "RÉUSSI (paquet reçu)"
    ((PASS_COUNT++))
  elif [[ "$3" == "DENY" && "$GREP_RET" -ne 0 ]]; then
    echo "RÉUSSI (bloqué)"
    ((PASS_COUNT++))
  else
    echo "ÉCHEC"
    ((FAIL_COUNT++))
  fi
}


function test_nc() {
  echo -n "[$1 -> $2:$3] attendu : $4 ... "
  #-v pour avoir plus de détail /-z juste pour voir si le port est ouvert / -w on attend 3sec d'avoir la réponse
  output=$(kathara exec $1 -- nc -vz -w 3 $2 $3 2>&1)

  if echo "$output" | grep -q "Connection refused"; then
    GOT="ALLOW"
  elif echo "$output" | grep -q "succeeded"; then
    GOT="ALLOW"
  elif echo "$output" | grep -q "open"; then
    GOT="ALLOW"
  elif echo "$output" | grep -q "timed out"; then
    GOT="DENY"
  else
    GOT="DENY"
  fi
  if [[ "$4" == "$GOT" ]]; then
    echo "RÉUSSI ($GOT)"
    ((PASS_COUNT++))
  else
    echo "ÉCHEC (obtenu $GOT, attendu $4)"
    ((FAIL_COUNT++))
  fi
}


function test_ssh() {


  echo -n "[$1 -> ssh $2] attendu : $3 ... "


  output=$(kathara exec "$1" -- ssh -o ConnectTimeout=3 root@"$2" "exit" 2>&1)
 
  if echo "$output" | grep -q "Connection refused"; then
    GOT="ALLOW"
  elif echo "$output" | grep -q "timed out"; then
    GOT="DENY"
  else
    GOT="DENY"
  fi


  if [[ "$GOT" == "$3" ]]; then
    echo "RÉUSSI ($GOT)"
    ((PASS_COUNT++))
  else
    echo "ÉCHEC (obtenu $GOT, attendu $3)"
    ((FAIL_COUNT++))
  fi
}


function test_curl_internet() {
  echo -n "[$1 -> http://216.58.214.14] attendu : $2 ... "
  #-I pour avoir uniquement l'entête de la réponse
  output=$(kathara exec "$1" -- curl -I http://216.58.214.14 2>&1)
  if echo "$output" | grep -q 'HTTP'; then
    GOT="ALLOW"
  else
    GOT="DENY"
  fi
  if [[ "$GOT" == "$2" ]]; then
    echo "RÉUSSI ($GOT)"
    ((PASS_COUNT++))
  else
    echo "ÉCHEC (obtenu $GOT, attendu $2)"
    ((FAIL_COUNT++))
  fi
}


function test_curl_server_s() {
  echo -n "[$1 -> http://$2] attendu : $3 ... "
  #-I pour avoir uniquement l'entête de la réponse
  output=$(kathara exec "$1" -- curl -I http://$2 2>&1)


  if echo "$output" | grep -q "Failed to connect"; then
    GOT="ALLOW"
  elif echo "$output" | grep -q "timed out"; then
    GOT="DENY"
  else
    GOT="DENY"
  fi


  if [[ "$GOT" == "$3" ]]; then
    echo "RÉUSSI ($GOT)"
    ((PASS_COUNT++))
  else
    echo "ÉCHEC (obtenu $GOT, attendu $3)"
    ((FAIL_COUNT++))
  fi
}


#Test sur pc employe

#pour voir ses mails
test_nc "pcaetudiant" "172.16.21.2" "993" "ALLOW"
#pour aller sur le site public/intranet
test_nc "pcaetudiant" "172.16.3.28" "80" "ALLOW"
test_nc "pcaetudiant" "172.16.3.28" "443" "ALLOW"
#ne peut pas acceder à la bdd/donnee anonymise
test_nc "pcaetudiant" "172.16.21.3" "3306" "DENY"
test_nc "pcaetudiant" "172.16.21.3" "22" "DENY"
#ne peut pas aller sur app rdv
test_nc "pcaetudiant" "172.16.21.28" "1224" "DENY"


#Test sur la machine d'un admin (ici)


#peut ping n'importe qui (on test une machine par serveur)
test_ping "rssi" "172.16.12.2" "ALLOW"
test_ping "rssi" "172.16.3.28" "ALLOW"
test_ping "rssi" "172.16.24.2" "ALLOW"
test_ping "rssi" "172.16.20.2" "ALLOW"
test_ping "rssi" "172.16.4.2" "ALLOW"
test_ping "rssi" "172.16.12.2" "ALLOW"
test_ping "rssi" "172.16.16.2" "ALLOW"
test_ping "rssi" "172.16.8.2" "ALLOW"
test_ping "rssi" "172.16.22.2" "ALLOW"
test_ping "rssi" "192.168.0.2" "ALLOW"
test_ping "rssi" "10.0.100.1" "ALLOW"
test_ping "rssi" "10.0.100.2" "ALLOW"
test_ping "rssi" "10.0.100.3" "ALLOW"

#peut accéder en ssh à toutes machines (une machine par serveur)
test_ssh "rssi" "172.16.22.2" "ALLOW"
test_ssh "rssi" "172.16.3.29" "ALLOW"
test_ssh "rssi" "172.16.24.2" "ALLOW"
test_ssh "rssi" "172.16.20.2" "ALLOW"
test_ssh "rssi" "172.16.4.2" "ALLOW"
test_ssh "rssi" "172.16.12.2" "ALLOW"
test_ssh "rssi" "172.16.8.2" "ALLOW"
test_ssh "rssi" "192.168.0.2" "ALLOW"
test_ssh "rssi" "10.0.10.1" "ALLOW"
test_ssh "rssi" "172.16.3.17" "ALLOW"
test_ssh "rssi" "172.16.24.1" "ALLOW"
test_ssh "rssi" "172.16.20.1" "ALLOW"
test_ssh "rssi" "172.16.4.1" "ALLOW"
test_ssh "rssi" "172.16.12.1" "ALLOW"
test_ssh "rssi" "172.16.16.1" "ALLOW"
test_ssh "rssi" "172.16.8.1" "ALLOW"
test_ssh "rssi" "172.16.22.1" "ALLOW"
test_ssh "rssi" "192.168.0.1" "ALLOW"
#ne peut pas acceder à la bdd (depuis mail)
test_nc "mail" "172.16.21.3" "3306" "DENY"


#Test du serveur S


#peut atteindre aux en sftp
test_nc "s" "172.16.21.4" "22" "ALLOW"
#on peut atteindre S sur le serveur public depuis un autre sous-réseau
test_curl_server_s "pcavisiteur" "172.16.3.28" "ALLOW"
test_curl_server_s "pcacomptabilite" "172.16.3.28" "ALLOW"
test_curl_server_s "pcaenseignants" "172.16.3.28" "ALLOW"
test_curl_server_s "pcaec" "172.16.3.28" "ALLOW"
test_curl_server_s "pcachercheurs" "172.16.3.28" "ALLOW"
test_curl_server_s "pcavisiteur" "172.16.3.28" "ALLOW"
test_curl_server_s "pcapatient" "172.16.3.28" "ALLOW"
#on ne peut pas ping serveur S depuis une machine hors DSI
test_ping "pcapatient" "172.16.3.28" "DENY"


#Test du routeur qui donne accès à internet


#on test si on a internet depuis le réseau low


test_curl_internet "pcavisiteur" "ALLOW"
#on test si on a internet depuis le réseau education
test_curl_internet "pcaetudiant" "ALLOW"
#on test si on a internet depuis le réseau low
test_curl_internet "pcapsoignant" "ALLOW"


#autre test

test_nc "pcavisiteur" "172.16.3.28" "22" "DENY"  # SSH non autorisé
test_nc "pcaetudiant" "172.16.21.2" "25" "DENY"  # SMTP bloqué

test_nc "pcachercheurs" "172.16.21.3" "22" "ALLOW"   # SFTP autorisé
test_nc "pcaetudiant" "172.16.21.3" "22" "DENY"      # SFTP interdit




# Bloquer le trafic sortant du routeur critique
kathara exec rcritique -- iptables -A OUTPUT -j DROP
# Tester l'accès Internet depuis un réseau critique (doit utiliser un autre routeur)
test_curl_internet "pcapsoignant" "ALLOW"
test_curl_internet "rssi" "ALLOW"
#Rétablir le routeur
kathara exec rcritique -- iptables -D OUTPUT -j DROP

# Autoriser uniquement le personnel soignant et la compta
test_nc "pcapsoignant" "172.16.3.28" "1224" "ALLOW"
test_nc "pcacomptabilite" "172.16.3.28" "1224" "ALLOW"
test_nc "pcavisiteur" "172.16.3.28" "1224" "DENY"  # Interdit pour les visiteurs

#Test d’Isolation de la Machine AUX
test_ping "pcaetudiant" "172.16.21.4" "DENY"  # AUX ne doit pas être pingable
test_ssh "rssi" "172.16.21.4" "ALLOW"         # Seul le RSSI peut y accéder

test_nc "pcachercheurs" "172.16.21.3" "3306" "DENY"  # MySQL interdit
test_nc "pcachercheurs" "172.16.21.3" "22" "ALLOW"   # SFTP autorisé

test_nc "s" "172.16.21.4" "22" "ALLOW"      # SFTP autorisé depuis S

test_ssh "pcaetudiant" "172.16.21.4" "DENY" # SSH interdit pour les étudiants

test_ssh "rssi" "172.16.21.3" "ALLOW"  # Accès DSI -> BDD
test_ssh "rssi" "172.16.21.2" "ALLOW"  # Accès DSI -> MAIL
test_ssh "rssi" "172.16.21.4" "ALLOW"  # Accès DSI -> AUX
test_ssh "rssi" "172.16.21.254" "ALLOW"  # Accès DSI -> Routeur DSI



echo
echo "=== RÉSUMÉ DES TESTS ==="
echo "RÉUSSIS : $PASS_COUNT"
echo "ÉCHECS : $FAIL_COUNT"
exit 0








