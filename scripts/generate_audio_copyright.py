import json
import os
import sys

def main():
    sys.stdout.reconfigure(encoding='utf-8')
    manifest_path = os.path.join('assets', 'media', 'manifest.json')
    with open(manifest_path, 'r', encoding='utf-8') as f:
        manifest = json.load(f)

    contents = manifest.get('contents', [])

    doc = []
    doc.append("# Certificat de Propriété Intellectuelle et Registre d'Antériorité Audio")
    doc.append("")
    doc.append("> **Statut juridique :** Propriété exclusive & Droits d'auteur réservés (Copyright © 2026 Hoppla!)")
    doc.append("> **Application :** Hoppla! (`de.hoppla.app`)")
    doc.append("> **Compte Développeur Google Play :** ID 6126448634029605589 (Taha kh)")
    doc.append("> **Contact légal & DMCA :** tahtoouh@gmail.com")
    doc.append("> **Date de certification :** 17 novembre 2026")
    doc.append("")
    doc.append("---")
    doc.append("")
    doc.append("## 1. Déclaration de Propriété Exclusive et Droits d'Auteur")
    doc.append("")
    doc.append("L'intégralité des créations sonores recensées ci-après (incluant les compositions musicales, arrangements, paroles chantées en langue allemande, transcriptions synchronisées trilingues DE/AR/FR et enregistrements vocaux) sont des **œuvres de l'esprit originales**, protégées par les traités internationaux sur la propriété intellectuelle, notamment :")
    doc.append("")
    doc.append("- La **Convention de Berne** pour la protection des œuvres littéraires et artistiques (articles 2 et 5) ;")
    doc.append("- Le **Traité de l'OMPI sur le droit d'auteur (WCT)** ;")
    doc.append("- Le **Digital Millennium Copyright Act (DMCA)** et les réglementations internationales équivalentes.")
    doc.append("")
    doc.append("### Clause d'Exclusivité Stricte :")
    doc.append("1. **Droit exclusif :** Seule l'application mobile officielle **Hoppla!** et son titulaire détiennent le droit d'exploiter, diffuser, lire et distribuer ces fichiers audio.")
    doc.append("2. **Interdiction formelle de copie et d'extraction :** Toute extraction (*reverse engineering*, décompilation d'APK/AAB, aspiration), redistribution, republication, revente, utilisation commerciale ou incorporation dans une application concurrente ou tierce sans accord écrit préalable est **strictement interdite**.")
    doc.append("3. **Sanctions :** Tout manquement constitue un acte de contrefaçon et de parasitisme commercial, entraînant immédiatement :")
    doc.append("   - Une notification formelle de retrait de contenu (**DMCA Takedown Notice**) auprès de Google Play, Apple App Store ou de l'hébergeur concerné ;")
    doc.append("   - Des poursuites judiciaires en dommages et intérêts pour violation de droits d'auteur.")
    doc.append("")
    doc.append("---")
    doc.append("")
    doc.append("## 2. Registre d'Empreintes Numériques SHA-256 (Preuve d'Antériorité)")
    doc.append("")
    doc.append("Les empreintes cryptographiques ci-dessous (hachages SHA-256 calculés sur chaque fichier audio original) constituent la preuve d'antériorité et d'intégrité numérique irréfutable de chaque œuvre sonore :")
    doc.append("")
    doc.append("| Lot | Type | Fichier | Durée | Taille | Empreinte SHA-256 (Preuve d'antériorité) |")
    doc.append("| :---: | :---: | :--- | :---: | :---: | :--- |")

    for c in contents:
        lot = c['lot_id']
        t = c['type'].capitalize()
        fn = c['audio_file']
        dur = f"{c['duration_seconds']} s"
        sz = f"{c['size_bytes']} o"
        sha = c['checksum']
        doc.append(f"| **Lot {lot}** | {t} | `{fn}` | {dur} | {sz} | `{sha}` |")

    doc.append("")
    doc.append("---")
    doc.append("")
    doc.append("## 3. Procédure de Signalement et Notification d'Infraction (DMCA)")
    doc.append("")
    doc.append("Pour toute notification d'atteinte aux droits d'auteur ou demande d'autorisation exceptionnelle d'utilisation, veuillez vous adresser directement au représentant légal à l'adresse suivante :")
    doc.append("")
    doc.append("📧 **Email :** `tahtoouh@gmail.com`  ")
    doc.append("📱 **Identifiant Développeur Google Play :** `6126448634029605589`  ")
    doc.append("🏢 **Projet :** Hoppla! Mobile Deutsch  ")
    doc.append("")

    with open('AUDIO_COPYRIGHT.md', 'w', encoding='utf-8') as f:
        f.write('\n'.join(doc))

    print(f"AUDIO_COPYRIGHT.md successfully generated with {len(contents)} audio items.")

if __name__ == '__main__':
    main()
