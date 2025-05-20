export-env {
    def fnm-env [] {
        let vars = (
            fnm env --shell bash
            | str replace -a 'export ' ''
            | str replace -a '"' ''
            | lines
            | split column '='
            | rename name value
            | reduce -f {} {|it, acc| $acc | upsert $it.name $it.value }
        )

        let fnm_path = ($vars.PATH | str replace ":$PATH" "")
        $vars | upsert PATH ($env.PATH | prepend $fnm_path)
    }

    if not (which fnm | is-empty) {
        fnm-env | load-env

        if (not ($env | default false __fnm_hooked | get __fnm_hooked)) {
            $env.__fnm_hooked = true

            $env.config = (
                $env.config | default {} | upsert hooks (
                    $env.config.hooks | default {} | upsert env_change (
                        $env.config.hooks.env_change | default {} | upsert PWD (
                            ($env.config.hooks.env_change.PWD | default []) ++ [{
                                |before, after|
                                if ([.nvmrc .node-version] | path exists | any { |it| $it }) {
                                    fnm use
                                }
                            }]
                        )
                    )
                )
            )
        }
    }
}
