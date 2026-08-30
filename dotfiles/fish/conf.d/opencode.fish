# Enable opencode's built-in websearch tool, backed by Exa, keyless.
#
# opencode gates websearch behind this flag. Without it the tool never gets
# registered in the model's toolset, so the agent cannot search at all and
# falls back to saying it does not know.
#
# Setting EXA_API_KEY unlocks Exa's free tier ($10/month in credits, roughly
# 1,400 searches at $7/1k). Put that key in ~/.config/fish-local.fish, not
# here: this file is a symlink into the system-config git repo.
set -gx OPENCODE_ENABLE_EXA true
