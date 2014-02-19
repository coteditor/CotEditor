CotEditor (Private Fork)
==========================

私家版CotEditorです。公式じゃありません。
手探りで弄り中なのでなんの保証もありません（一応手元ではそれなりに動いています）。

口出し歓迎。


改造点
-------------
公式の1.3.1から以下の点が変更されています。

- 対応OSをMac OS X 10.6以上に変更
- 64-bit対応
- ツールバーアイコンなどの画像類のRetina対応
- シンタックス定義の追加および更新（[wolfrosch.com](http://wolfrosch.com/works/goodies/coteditor_syntax)で配布しているものと同一）
    - 追加: Apache, Markdown, Scala, XML
    - 更新: PHP, Python
- ファイル保存を短期間に連続して行なったときに「別のプロセスによって変更されました。」というアラートが出る問題を解決
	- それ以外のケースの不意に変更アラートが出る問題については様子見 ([ticket 27779](https://sourceforge.jp/ticket/browse.php?group_id=1836&tid=27779))
		- まだ出るようだったら教えてください
- 環境設定のラベルのtypoを修正 ([ticket 29798](https://sourceforge.jp/ticket/browse.php?group_id=1836&tid=29798))
- ステータスバーのフォントをシステムフォントに変更 ([ticket 29850](https://sourceforge.jp/ticket/browse.php?group_id=1836&tid=29850))
- 言語がEnglishのときのツールバーラベルの単語間ブランクを修正
- CotEditor 1.1で4.0に更新されたはずのRegexKitLiteが実際には更新されていなかったのを修正
- ライセンス類の表記を更新

### そのほか内部的な変更
- SDKをMaveriksに
- Modern Objective-C Syntaxに変換
- OgreKitを最新版にアップデート
- UKKQueue をよりモダンな VDKQueue に変更
	- さらに、Notification で通知を行なっていたのを delegate によるものにした
- deprecatedなコードを置き換えるなどWarning類をできるだけ潰した
- Deployment Targetを上げたことによって使われなくなったコードを削除
- `for` ループで簡単に置き換え可能な箇所は高速列挙を使用
- ヘルプコンテンツのフォーマットをXHTML1.1, LF, UTF-8に変更し .help 形式に改めた


現在の問題点
-------------
### 64-bit 対応における `objc_msgSend` のキャスト
64-bit に対応するには、`objc-msgSend` をキャストしないといけない。CotEditorではCDDocument内の2368行目らへんで `objc_msgSend` を使っている。
が、やり方が正直よくわかってない。最後の `void *` をどうすれば良いのかが不明。

現状放置されているが、その行が実行されることがまずないので今のところ問題には至っていない。
また、無理矢理その部分を実行した場合も、今のところクラッシュしたりはしていない。


開発環境
-------------
- MacBook Pro (late 2011)
- OS X 10.9.1
- Xcode 5.0.2


今後の展望
-------------
やるという意味ではありません。だったらいいな、ということです。

- TeXのシンタックス定義をどうにかしたい
- アプリケーションアイコンをブラッシュアップしたい（万年筆のディティールを変えたい）
- ARCに移行したい
- VDKQueueによるファイル更新通知をNSFilePresenterのメソッド `presentedItemDidChange` で置き換えたい（Deployment targetを10.7以降にする必要がある）
- NSDocumentサブクラスにあるウインドウの透明度関連のコードをNSWindowControllerサブクラスに移したい


CotEditor更新されないなぁ、と思ってちょっと弄りだしてみたのですが、今後どうしようかと自分でも路頭に迷い中。
