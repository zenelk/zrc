#############################
# ZRC (Zenel's RC)
# Manages module loaded / common functionality 
# in rc files to be shared across machines/
#############################
_ZRC_LOADED_MODULES=()
_ZRC_DISABLE_MODULE_MANAGEMENT=false
_ZRC_MODULES_DIR="$ZRC_DIR/modules"

#############################
# Check Config
#############################

if [ ${#ZRC_MODULES[@]} -eq 0 ]; then
	echo "ZRC_MODULES is empty! Did you mean to do this? Define them in your '~/.zshrc' file."
fi

if [ -z $ZRC_DIR ]; then
	echo "No ZRC_DIR! Modules cannot be loaded without this path. Define it in your '~/.zshrc' file."
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
			echo "Module management is disabled because there is no module source directory specified. Define 'ZRC_DIR' in your '~/.zshrc' and 'rez' to re-enable."
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
		subl "$ZRC_MODULES_DIR"
		;;
	add)
		load_module "$2"
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
	if [[ "$_ZRC_LOADED_MODULES" == *"$1"* || "$_ZRC_LOADED_MODULES" == *"$_ZRC_MODULES_DIR/$1.zrc_module"* ]]; then
		echo "1"
	else
		echo "0"
	fi
}

function load_module() {
	if [ ! -d "$_ZRC_MODULES_DIR" ]; then
		echo "No modules directory!"
		return
	fi
	if [[ "${module: -1}" == "@" ]]; then
		no_link="${module::-1}"
		module="$(readlink "$no_link")"
	elif [ ! -e "$module" ]; then
		module="$_ZRC_MODULES_DIR/$module.zrc"
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