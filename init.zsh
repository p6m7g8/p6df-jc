p6df::modules::jc::version() { echo "0.0.1" }

p6df::modules::jc::deps()   {
    ModuleDeps=(
        p6m7g8/p6common
    )
}

p6df::modules::jc::external::brew() { }

p6df::modules::jc::init() {

  local dir="$P6_DFZ_SRC_DIR/p6m7g8/p6df-jc"
  p6_bootstrap "$dir"

  p6df::util::path_if "$dir/bin"
}
