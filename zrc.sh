#############################
# ZRC (Zenel's RC)
# Manages module loaded / common functionality 
# in rc files to be shared across machines/
#############################
export _ZRC_LOADED_MODULES=()
export _ZRC_DISABLE_MODULE_MANAGEMENT=false

#############################
# Check Config
#############################

if [ ${#ZRC_MODULES[@]} -eq 0 ]; then
	echo "ZRC_MODULES is empty! Did you mean to do this? Define them in your '~/.zshrc' file."
fi

if [ -z $ZRC_MODULE_DIRECTORY ]; then
	echo "No ZRC_MODULE_DIRECTORY! Modules cannot be loaded without this path. Define it in your '~/.zshrc' file."
	_ZRC_DISABLE_MODULE_MANAGEMENT=true
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
			echo "Module management is disabled because there is no module source directory specified. Define 'ZRC_MODULE_DIRECTORY' in your '~/.zshrc' and 'rez' to re-enable."
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
		subl "$ZRC_MODULE_DIRECTORY"
		;;
	add)
		local sourceModulePath="$ZRC_MODULE_DIRECTORY/$2"
		echo "$sourceModulePath"
		if [ -e "$sourceModulePath" ]; then
			local newModulePath="$ZRC_MODULE_DIRECTORY/$2"
		elif [ -e "$sourceModulePath.zrc_module" ]; then
			local newModulePath="$ZRC_MODULE_DIRECTORY/$2.zrc_module"
			sourceModulePath="$ZRC_MODULE_DIRECTORY/$2.zrc_module"
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
	if [ ! -d "$ZRC_MODULE_DIRECTORY" ]; then
		echo "No modules directory!"
		return
	fi
	if [[ "${module: -1}" == "@" ]]; then
		no_link="${module::-1}"
		module="$(readlink "$no_link")"
	elif [ ! -e "$module" ]; then
		module="$ZRC_MODULE_DIRECTORY/$module.zrc"
		if [ ! -e "$module" ]; then
			echo "Cannot find module $1 as itself or as path $module"
			return
		fi
	fi
	
	_ZRC_LOADED_MODULES+=($1)
	source "$module"
}

for module in "${ZRC_MODULES[@]}"; do
	load_module "$module"
done

alias rez="source $0"