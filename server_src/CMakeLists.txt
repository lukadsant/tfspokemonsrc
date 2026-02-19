# --- Início do Bloco Final e Definitivo ---
cmake_minimum_required(VERSION 3.10)
project(TheForgottenServer)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# --- ENCONTRANDO BIBLIOTECAS ---
# Para Boost e Threads, o método padrão funciona bem
find_package(Boost REQUIRED COMPONENTS system filesystem iostreams)
find_package(Threads REQUIRED)

# Para as bibliotecas com .pc, usamos pkg-config
find_package(PkgConfig REQUIRED)
pkg_check_modules(PUGIXML REQUIRED pugixml)
pkg_check_modules(MYSQLCLIENT REQUIRED mysqlclient)
pkg_check_modules(LUA REQUIRED lua5.2)

# Para Crypto++ e GMP, que não tem .pc, encontramos manualmente
find_path(CRYPTOPP_INCLUDE_DIR NAMES cryptopp/osrng.h)
find_library(CRYPTOPP_LIBRARY NAMES cryptopp)
find_path(GMP_INCLUDE_DIR NAMES gmp.h)
find_library(GMP_LIBRARY NAMES gmp)

# --- INCLUINDO OS CABEÇALHOS ---
include_directories(
	${Boost_INCLUDE_DIRS}
	${PUGIXML_INCLUDE_DIRS}
	${MYSQLCLIENT_INCLUDE_DIRS}
	${LUA_INCLUDE_DIRS}
	${CRYPTOPP_INCLUDE_DIR} # Adicionado manualmente
	${GMP_INCLUDE_DIR}      # Adicionado manualmente
)

# --- ENCONTRANDO OS ARQUIVOS-FONTE ---
file(GLOB tfs_SRC "src/*.cpp")

# --- CRIANDO O EXECUTÁVEL ---
add_executable(tfs ${tfs_SRC})

# --- LINKANDO AS BIBLIOTECAS ---
target_link_libraries(tfs
	# Bibliotecas encontradas pelo find_package padrão
	Boost::system Boost::filesystem Boost::iostreams
	Threads::Threads

	# Bibliotecas encontradas pelo pkg-config
	${PUGIXML_LIBRARIES}
	${MYSQLCLIENT_LIBRARIES}
	${LUA_LIBRARIES}

	# Bibliotecas encontradas manualmente
	${CRYPTOPP_LIBRARY}
	${GMP_LIBRARY}

	# Bibliotecas do sistema
	dl
)
# --- Fim do Bloco Final e Definitivo ---
