import smtplib
import os
import requests
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def SendEmail(password_id, key_file):
    email_to = 'kevin.bickmore@domain.com' 
    with open(key_file, 'r') as f:
        header = {'APIKey': f.read().strip()}
    url = 'https://enigma/api/passwords/{}'.format(password_id)
    response_json = requests.get(url, headers=header, verify='/Users/kbickmore/Documents/OfflineCA.pem').json()
    username = response_json[0][u'UserName']
    password = response_json[0][u'Password']

    sender = 'ConjunctionJunction-Report@domain.com'
    print(sender)
    subject = 'Python Auth Test'
    text = 'This is a test email sent with authentication from Kevin Bickmore as {}.'.format(sender)
    msg = MIMEMultipart('related')
    msg['Subject'] = subject
    msg['From'] = sender
    msg['To'] = email_to
    msg.attach(MIMEText(text))

    email_sent = False
    emailAttempts = 0
    while email_sent == False and emailAttempts <= 2:
        emailAttempts +=1
        try:
            smtpserver = smtplib.SMTP("smtp.domain.com", 25)
            smtpserver.ehlo()
            smtpserver.starttls()
            smtpserver.login(username, password)
            smtpserver.ehlo
            smtpserver.sendmail(sender, email_to, msg.as_string())
            smtpserver.close()
            email_sent = True
            print ('Email sent successfully')

        except smtplib.SMTPAuthenticationError as sae:
            print(str(sae))
        
        except smtplib.SMTPException as e:
            print(str(e))

SendEmail(325084, '/Users/kbickmore/Documents/conjunction.txt')





