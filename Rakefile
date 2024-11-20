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
  system 'cargo build --release'
  system 'wasm-pack build'

  Dir.chdir 'www' do
    system 'rm dist/*'
    system 'pnpm install'
    system 'pnpm run build'
  end

  # manual shtuff:
  #
  # Dir.chdir 'public' do
  #   system 'rm *'
  #   system 'cp ../www/dist/* .'
  #   system 'git add --all && git commit -m "pub" && git push'
  # end
end
