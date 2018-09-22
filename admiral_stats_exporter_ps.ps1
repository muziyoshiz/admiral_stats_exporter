# Simple admiral stats exporter from kancolle-arcade.net for Windows PowerShell
# プログラム翻案： KOIZUMI Naoki (@sophiarcp)

function putJson2AS ($json_dir, $access_token) {
    # Upload exported files to Admiral Stats
    # 戻り値:
    # 0 : 正常終了
    # 1 : インポート対象ファイルタイプ取得エラー(401)
    # 2 : インポート対象ファイルタイプ取得エラー(その他)
    # 3 : インポート実行時のエラー(400,401)
    # 4 : インポート実行時のエラー(その他)

    # Admiral Stats Import URL
    $AS_IMPORT_URL = 'https://www.admiral-stats.com/api/v1/import'

    # User Agent for logging on www.admiral-stats.com
    $AS_HTTP_HEADER_UA = 'AdmiralStatsExporter-PS/1.15.0'

    # Set Authorization header
    $headers = @{ "Authorization" = ("Bearer", $access_token -join " ") }

    # Get currently importable file types
    try {
        $uri = "$AS_IMPORT_URL/file_types"
        $importable_file_types = Invoke-RestMethod -uri $uri -Method Get -Headers $headers -UserAgent $AS_HTTP_HEADER_UA -ErrorAction stop
        Write-host "Importable file types: $importable_file_types"
    } catch {
        switch ($error[0].Exception.Response.StatusCode.value__) {
            401 {
                Write-Host "ERROR: "$Error[0]
                return 1
            }
            default {
                Write-Host "ERROR: "$Error[0]
                return 2
            }
        }
    }

    foreach ($json_file in (Get-ChildItem "$json_dir\*.*" -include *.json)) {
        $dummy = $json_file.name -match "(.*)_(\d{8}_\d{6})\.json$"
        $file_type = $matches[1]
        $timestamp = $matches[2]
        if ( -not ($importable_file_types -contains $file_type) ) { continue }

        $json = get-content $json_file -Raw -encoding UTF8

        # この GetBytes() がないと、UTF-8 を含む Body（例：艦娘一覧の装備スロット）が
        # UTF-8 として認識されず、送信時に文字化けする
        # 参考：https://www.uramiraikan.net/Works/entry-2798.html
        $json = [System.Text.Encoding]::UTF8.GetBytes($json)

        $uri = "$AS_IMPORT_URL/$file_type/$timestamp"
        $res = ""
        try {
            $res = Invoke-WebRequest -uri $uri -UseBasicParsing -Method Post -Body $json -ContentType 'application/json' -UserAgent $AS_HTTP_HEADER_UA -Headers $headers
            
            switch -regex ($res.StatusCode) {
                "20[01]" {
                    $resJson = ConvertFrom-Json($res.content)
                    Write-Host $resjson.data.message"（ファイル名："$json_file.name"）"
                }
                default {
                    Write-Host "ERROR: $res.content"
                }
            }
        } catch {
            switch -regex ($error[0].Exception.Response.StatusCode.value__) {
                "40[01]" {
                    Write-host "ERROR: "$error[0]
                    return 3
                }
                default {
                    Write-host "ERROR: "$error[0]
                    return 4
                }
            }
        }
    }
    return 0
}


$api_base = "https://kancolle-arcade.net/ac/api/"
$ymdhms = get-date -Format "yyyyMMdd_HHmmss"
$outdir = ".\json\" + $ymdhms
$credential_path = ".\cred.xml"
$token_path = ".\token.dat"
$do_upload = $false

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

# Check whether to upload JSON files or not
if ( $args[0] -eq "--upload" ) { 
    $do_upload = $true
    if ( Test-Path $token_path ) {
        $access_token = Get-Content $token_path -Encoding ascii
    } else {
        try {
            $access_token = Read-Host "初回実行のためAdmiral StatsのAPIトークンを入力してください。"
            if ( $access_token -ne "" ) {
                $access_token | out-file $token_path -Encoding ascii #| Out-Null
            } else {
                Write-Host "トークン情報が入力されていません。処理を中断します。"
                exit 4
            }
        } catch { 
            Write-Host $error[0]
            Write-Host "トークン情報の取得/保存中にエラーが発生しました。処理を中断します。"
            exit 5
        }
        echo "$token_path に保存しました。"
     }
}

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
    $infoarray = @("Personal/basicInfo", 'Area/captureInfo', 'TcBook/info', 'EquipBook/info', 'Campaign/history', 'Campaign/info', 'Campaign/present', 'CharacterList/info', 'EquipList/info', 'Quest/info', 'Event/info', 'RoomItemList/info', 'BlueprintList/info', 'Exercise/info', 'Cop/info')
    foreach( $infoaddr in $infoArray ) {
        $outfn = $outdir + "\" + $infoaddr.Replace("/", "_") + "_" + $ymdhms + ".json"
        $uri = $api_base + $infoaddr
        #Invoke-RestMethod -uri $uri -Method Get -Headers $headers -WebSession $sv | ConvertTo-Json -Compress | Out-File $outfn #Invoke-RestMethod 
        Invoke-WebRequest -Uri $uri -UseBasicParsing -WebSession $sv -Headers $headers -OutFile $outfn 

        # 204 (No Content) が返された場合はファイルサイズが空になる。その場合はファイルを削除する
        # Invoke-WebRequest には、正常終了時のステータスコードを取得する方法がなかったため、ファイルサイズで判断
        if ((Get-ChildItem $outfn).Length -eq 0) {
            echo "ダウンロードしたファイルが空のため、削除します。対象ファイル: $outfn"
            Remove-Item $outfn
        }
    }
} catch {
    echo "データ取得中にエラーが発生しました。対象アドレス:  $uri"
    exit 3
}

echo "データ取得が完了しました。"
echo "保存先: $outdir"

# Upload exported files to Admiral Stats
if ($do_upload) {
    $ret = putJson2AS $outdir $access_token
    switch ($ret) {
        {1,3 -contains $_ } {
            Write-Host "APIトークンが正しくない可能性があります。$token_path を修正するか、削除して再登録してください。"
        }
    }
}
