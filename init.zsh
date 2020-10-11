p6df::modules::jc::deps()   { ModuleDeps=() }
p6df::modules::jc::external::brew() { }

p6df::modules::jc::init() {

    p6_jc_init "$P6_DFZ_SRC_DIR/p6m7g8/p6df-jc"
}

p6_jc_init() {
    local dir="$1"

    p6df::util::path_if "$dir/bin"

    p6_file_load "$dir/lib/create.sh"
}
