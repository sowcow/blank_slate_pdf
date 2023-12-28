dir = File.join __dir__, '..'
path = -> given {
  File.expand_path File.join(dir, given)
}

$noto = path.call './fonts/Noto_Sans_Symbols/static/NotoSansSymbols-Medium.ttf'
$noto_semibold = $noto.sub('Medium', 'SemiBold')
$noto_thin = $noto.sub('Medium', 'Thin')
$noto_light = $noto.sub('Medium', 'Light')

# used for calendar:
$roboto = path.call './fonts/Roboto/Roboto-Regular.ttf'
$roboto_light = path.call './fonts/Roboto/Roboto-Light.ttf'
#$roboto_thin = path.call './fonts/Roboto/Roboto-Thin.ttf'
$roboto_bold = path.call './fonts/Roboto/Roboto-Bold.ttf'
