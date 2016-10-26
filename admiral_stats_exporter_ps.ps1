# Simple admiral stats exporter from kancolle-arcade.net for Windows PowerShell
# プログラム翻案： KOIZUMI Naoki (@sophiarcp)

$api_base = "https://kancolle-arcade.net/ac/api/"
$ymdhms = get-date -Format "yyyyMMdd_HHmmss"
$outdir = ".\json\" + $ymdhms
$credential_path = ".\cred.xml"

if ( -not(Test-Path $credential_path )) {
    try {
        Get-Credential -Message "初回実行のためプレイヤーズサイトの認証情報を登録してください。" | Export-Clixml $credential_path | Out-Null
    } catch {
        exit 4
    }
    echo "$credential_path に保存しました。"
}

$credential = Import-Clixml $credential_path
$username = $credential.UserName
$pass = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password))

$err = 0

$headers = @{ "Referer" = "https://kancolle-arcade.net/ac/"; "X-Requested-With" = "XMLHttpRequest" ; "Host" = "kancolle-arcade.net" }
$bodytext = '{"id":"' + $username + '","password":"' + $pass + '"}'

try {
    $res = Invoke-RestMethod -uri "https://kancolle-arcade.net/ac/api/Auth/login" -Method Post -Body $bodytext -ContentType 'application/json' -Headers $headers -SessionVariable sv
    
    if (-not($res.login)) {
        echo "認証に失敗しました。ユーザー名またはパスワードが間違っています。"
        echo "パスワードの登録を間違えた場合は、 $credential_path を削除して再実行してください。"
        exit 1
    }
} catch {
    echo "認証に失敗しました。プレイヤーズサイトが停止しているか、メンテナンス中(2:00～7:00)です。"
    exit 2
}

New-Item $outdir -ItemType Directory -Force | Out-Null

try {
    $infoarray = @("Personal/basicInfo", 'Area/captureInfo', 'TcBook/info', 'EquipBook/info', 'Campaign/history', 'Campaign/info', 'Campaign/present', 'CharacterList/info', 'EquipList/info', 'Quest/info', 'Event/info')
    foreach( $infoaddr in $infoArray ) {
        $outfn = $outdir + "\" + $infoaddr.Replace("/", "_") + "_" + $ymdhms + ".json"
        $uri = $api_base + $infoaddr
        #Invoke-RestMethod -uri $uri -Method Get -Headers $headers -WebSession $sv | ConvertTo-Json -Compress | Out-File $outfn #Invoke-RestMethod 
        Invoke-WebRequest -Uri $uri -UseBasicParsing -WebSession $sv -Headers $headers -OutFile $outfn 
    }        
} catch {
    echo "データ取得中にエラーが発生しました。対象アドレス:  $uri"
    exit 3
}

echo "データ取得が完了しました。"
echo "保存先: $outdir"