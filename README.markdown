CotEditor (Private Fork)
==========================

私家版CotEditorです。公式じゃありません。
手探りで弄り中なので安定してませんしなんの保証もありません（一応手元ではそれなりに動いています）。

口出し歓迎。


改造点
-------------
公式の1.3.1から以下の点が変更されています。

- 対応OSをMac OS X 10.6以上に変更
- 64-bit対応
- Retina対応
- シンタックス定義の追加および更新（wolfrosch.comで配布しているものと同一）
    - 追加: Apache, Markdown, Scala, XML
    - 更新: PHP, Python
- ツールバーラベルの単語間ブランクを修正
- 環境設定のラベルのtypoを修正 ([ticket 29798](https://sourceforge.jp/ticket/browse.php?group_id=1836&tid=29798))
- ステータスバーのフォントをシステムフォントに変更 ([ticket 29850](https://sourceforge.jp/ticket/browse.php?group_id=1836&tid=29850))
- RegexKitLite が（おそらく）4.0に上がっていなかったのを修正
- ライセンス類の表記を更新

### 内部
- SDKをMaveriksに
- Modern Objective-C Syntaxに変換
- OgreKitを最新版にアップデート
- deprecatedなコードを置き換えるなどWarning類をできるだけ潰した
- Deployment Targetを上げたことによって使われなくなったコードを削除
- 簡単に置き換え可能な箇所は高速列挙を使用
- ヘルプコンテンツのフォーマットをXHTML1.1, LF, UTF-8に変更


開発環境
-------------
- MacBook Pro (late 2011)
- OS X 10.9.1
- Xcode 5.0.2


今後の展望
-------------
やるという意味ではありません。だったらいいな、ということです。

- TeXのシンタックス定義をどうにかしたい
- ARCに移行したい
- UKKQueueをNSFilePresenterのメソッドで置き換えたい（Deployment targetを10.7以降にする必要がある）
- NSDocumentサブクラスにあるウインドウの透明度関連のコードをNSWindowControllerに移したい

