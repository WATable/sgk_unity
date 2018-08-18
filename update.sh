echo "press enter to start"
read

echo "--------------------"

git fetch -a
git checkout ProjectSettings/GraphicsSettings.asset
git pull origin master

echo "--------------------"
echo "press enter to exit"
read