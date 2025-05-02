function new_project
    read -P "Enter project name: " name
    set dir ~/projects/personal/$name
    mkdir -p $dir
    cd $dir
end
