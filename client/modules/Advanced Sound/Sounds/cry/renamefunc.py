import os
import re

def renomear_pokemon():
    # Obtém o diretório onde o script está sendo executado
    diretorio_atual = os.getcwd()
    # Nome deste script para evitar que ele renomeie a si mesmo
    nome_do_script = os.path.basename(__file__)
    
    arquivos = os.listdir(diretorio_atual)
    
    for nome_antigo in arquivos:
        # Pula pastas e o próprio script
        if os.path.isdir(nome_antigo) or nome_antigo == nome_do_script:
            continue
            
        nome_base, extensao = os.path.splitext(nome_antigo)
        
        # 1. Identifica se é Mega X ou Y antes de limpar o nome
        # Criamos flags para facilitar a contagem de exclamações
        eh_mega_x = "(MEGA X)" in nome_base.upper()
        eh_mega_y = "(MEGA Y)" in nome_base.upper()
        eh_mega_comum = "MEGA" in nome_base.upper() and not (eh_mega_x or eh_mega_y)

        # 2. Remove o prefixo (Ex: "001 - " ou "003M - ")
        novo_nome = re.sub(r'^[0-9A-Z]+\s*-\s*', '', nome_base)
        
        # 3. Remove parênteses e caracteres especiais, mantendo letras e espaços
        novo_nome = re.sub(r'\(.*?\)', '', novo_nome) # Remove o que está entre parênteses
        novo_nome = re.sub(r'[^\w\s]', '', novo_nome) # Remove outros símbolos
        novo_nome = novo_nome.strip().upper()
        
        # 4. Define a quantidade de exclamações
        if eh_mega_y:
            novo_nome += "!!!"
        elif eh_mega_x or eh_mega_comum:
            novo_nome += "!!"
        else:
            novo_nome += "!"

        # Caminhos para renomear
        try:
            os.rename(nome_antigo, novo_nome + extensao)
            print(f"Sucesso: {nome_antigo} -> {novo_nome + extensao}")
        except Exception as e:
            print(f"Erro ao renomear {nome_antigo}: {e}")

if __name__ == "__main__":
    renomear_pokemon()
