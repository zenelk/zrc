#############################
# ZRC (Zenel's RC)
# Manages module loaded / common functionality 
# in rc files to be shared across machines/
#############################
export _ZRC_LOADED_MODULES=""
export _ZRC_USE_DEFAULT_MODULE_DIRECTORY=false
export _ZRC_DEFAULT_MODULE_DIRECTORY="$HOME/.zrcmodules"
export _ZRC_DISABLE_MODULE_MANAGEMENT=false

#############################
# Check Config
#############################

if [ -z $ZRC_MODULE_DIRECTORY ]; then
	_ZRC_USE_DEFAULT_MODULE_DIRECTORY=true
elif [ ! -e $ZRC_MODULE_DIRECTORY ]; then
	echo "ZRC Warning: Invalid module directory '$ZRC_MODULE_DIRECTORY'! Using default at '$_ZRC_DEFAULT_MODULE_DIRECTORY'"
	_ZRC_USE_DEFAULT_MODULE_DIRECTORY=true
fi

if [ "$_ZRC_USE_DEFAULT_MODULE_DIRECTORY" = true ]; then
	ZRC_MODULE_DIRECTORY="$_ZRC_DEFAULT_MODULE_DIRECTORY"
fi

if [ -z $ZRC_MODULE_SRC_DIRECTORY ] || [ ! -e $ZRC_MODULE_SRC_DIRECTORY ]; then 
	echo "ZRC Warning: No directory specified for module source. Module management is disabled."
	_ZRC_DISABLE_MODULE_MANAGEMENT=1
fi

#############################
# Util
#############################
function cdup() {
	for i in $(seq 1 $1); do
		cd ..
	done
}

#############################
# ZRC Management
#############################
zrc() {
	case $1 in
	mod)
		if [ "$_ZRC_DISABLE_MODULE_MANAGEMENT" = true ]; then
			echo "Module management is disabled because there is no module source directory specified. Define 'ZRC_MODULE_SRC_DIRECTORY' in your '~/.zshrc' and 'rez' to re-enable."
			return 1
		fi
		shift
		_zrc_mod $@
		;;
	esac
}

_zrc_mod() {
	case $1 in
	edit)
		subl "$ZRC_MODULE_SRC_DIRECTORY"
		;;
	add)
		local sourceModulePath="$ZRC_MODULE_SRC_DIRECTORY/$2"
		echo "$sourceModulePath"
		if [ -e "$sourceModulePath" ]; then
			local newModulePath="$ZRC_MODULE_DIRECTORY/$2"
		elif [ -e "$sourceModulePath.zrc_module" ]; then
			local newModulePath="$ZRC_MODULE_DIRECTORY/$2.zrc_module"
			sourceModulePath="$ZRC_MODULE_SRC_DIRECTORY/$2.zrc_module"
		else
			echo "Module '$2' does not exist!"
			return 1
		fi
		
		ln -s "$sourceModulePath" "$newModulePath"
		load_module "$newModulePath"
		;;
	esac
}

#############################
# Module loading
#############################
function require_module() {
	is_loaded=$(is_module_loaded $1)
	if [[ $is_loaded == "1" ]]; then
		return
	fi
	load_module $1
}

function is_module_loaded() {
	if [[ "$_ZRC_LOADED_MODULES" == *"$1"* || "$_ZRC_LOADED_MODULES" == *"$ZRC_MODULE_DIRECTORY/$1.zrc_module"* ]]; then
		echo "1"
	else
		echo "0"
	fi
}

function load_module() {
	module="$1"
	if [ ! -d "$ZRC_MODULE_DIRECTORY" ]; then
		echo "No modules directory!"
		return
	fi
	if [[ "${module: -1}" == "@" ]]; then
		no_link="${module::-1}"
		module="$(readlink "$no_link")"
	elif [ ! -e "$module" ]; then
		module="$ZRC_MODULE_DIRECTORY/$module.zrc_module"
		if [ ! -e "$module" ]; then
			echo "Cannot find module $1 as itself or as path $module"
			return
		fi
	fi
	
	export _ZRC_LOADED_MODULES="$_ZRC_LOADED_MODULES$1;"
	source "$module"
}

if [ -d "$ZRC_MODULE_DIRECTORY" ]; then
	for module in $(ls "$ZRC_MODULE_DIRECTORY"); do
		load_module "$ZRC_MODULE_DIRECTORY/$module"
	done
else 
	echo "Creating modules directory at $ZRC_MODULE_DIRECTORY"
	mkdir "$ZRC_MODULE_DIRECTORY"
fi

alias rez="source $0"