### A10. Amazon Cognito

Zdecydowałam, że wykorzystam do procesu logowania i rejestracji interfejs z przykładu, napisany w języku React.

Czyli, do urochomenia aplikacji potrzebowałam czterech rzeczy:
1. Uruchomienie aplikacji React na poprawnym porcie
2. Po udanym zalogowaniu przekierowanie użytkownika do głównej strony gry
3. W tym, przekazanie logina użytkownika
4. Tworzenie poprawnie działającego poola uzytkowników za pomocą terraform.

Podczas robienia punktów 1 i 2 duże problemy nie wystąpiły. W punkcie 3 podczas odczytywania z cookies logina (czyli  adresu email) pojawił się problem z formatowanie plików cookie - pojawiły się symbole "%20", "%40", psujące ogólny wygląd logina użytkownika. Udało się rozwiązać ten problem za pomocą dwóch funkcji: 
```javascript
   const decodedCookieValue = decodeURIComponent(cookieValue);
   const emailObject = JSON.parse(decodedCookieValue);
```

Prawdziwym wyzwaniem okazał się punkt 4, który wymagał poprawnej konfiguracji terraform.

Kiedy udało się uruchomić tworzenie poola użytkowników (w kodzie to jest resource "aws_cognito_user_pool" "pool"), zrozumiałam, że brakuje mi pliku config.json.

W moim kodzie plik config.json odpowiada za dane wymagane do połączenia do cognito: clientId, region, userPoolId. Wiadomo, że pobierając z git'a kod, nie mogłam pobrać danych o utworzonej przez terraform puli użytkowników.

Aby rozwiązać ten problem zrobiłam:

1. Utowrzyłam config.json lokalnie:

```terraform
resource "local_file" "config_json" {
  content = jsonencode({
    region = "us-east-1"
    userPoolId = aws_cognito_user_pool.pool.id
    clientId   = aws_cognito_user_pool_client.client.id
  })
  filename = "${path.module}/frontend/frontend-client-react/src/config.json"
}
```

2. Wysłałam za pomocą ssh plik na instancję ec2:

```terraform
  provisioner "file" {
    source      = "${path.module}/frontend/frontend-client-react/src/config.json"
    destination = "/home/ubuntu/config.json"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/environment/aws-lab.3/labsuser10.pem")
    host        = self.public_ip
  }
```

3. W skrypcie run.sh, który uruchamia się po utowrzeniu instacji ec2, przerzuciłam ten plik do poprawnego folderu:
   
```bash
cp -f config.json a10-KatsiarynaViarenich/frontend/frontend-client-react/src
```

Po dużej liczbie nieudanych prób, udało się uruchomić taki kod. 

I wtedy nastąpił kolejny, ostatni problem: aplikacja nie wysyłała kod potwierdzenia po rejestracji nowego użytkownika.

Okazało się, że problem tkwił w braku uprawnień - udało się to rozwiązać, dodając następne linijki do konfiguracji w terraform:

```terraform
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject = "Your verification code"
    email_message = "Your verification code is {####}"
  }

  auto_verified_attributes = ["email"]
```

















