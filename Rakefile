# Setup:
#
# git checkout --orphan gh-pages
# git commit -m ok --allow-empty
# git push --set-upstream origin gh-pages
# git checkout master
# 
# (rm -rf public)
# (git worktree prune)
# git worktree add -B gh-pages public origin/gh-pages

task :default do
  got = system 'cargo build --release'
  unless got
    puts 'Failed'
    exit 0
  end
  system 'wasm-pack build'

  Dir.chdir 'www' do
    system 'rm dist/*'
    system 'pnpm install'
    system 'pnpm run build'
  end
end

# does it work from rake or only manual?
task :shtuff do
  Dir.chdir 'public' do
    system 'rm *'
    system 'cp ../www/dist/* .'
    system 'git add --all && git commit -m "pub" && git push'
  end
end

task :dev do
  sh 'watchexec -r -e rs,toml -- rake dev_one'
end

task :dev_one do
  sh 'cargo build; wasm-pack build; cd www; pnpm install; pnpm run start'
end
