# SHIROKANEでfastqファイルからbamファイルを作成する解析パイプライン

# master.shで以下の変数を設定してから、qsub master.shを実行して下さい。

# OUTDIR；処理結果(bamファイルなど)を出力するディレクトリのパス。
# LOG；logファイルの出力先
# SCRIPTDIR；実行するスクリプト（このスクリプト）を含むディレクトリのパス。
# DATDIR；fastqファイルを含むディレクトリのパス
# INDEX；リファレンスゲノムのパス
# SampleFolderNamesList；DATDIR内のフォルダ名。この変数中のフォルダに含まれるfastqファイルに対して処理が実行されます。