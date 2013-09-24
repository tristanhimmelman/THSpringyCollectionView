THSpringyCollectionView
=======================

A memory and CPU efficient implementation of a collection view with cells that bounce around like they do in the iOS 7 messages app.

![Screenshot](https://raw.github.com/tristanhimmelman/THSpringyCollectionView/master/messages-ios-7-app.jpeg)

This is implemented by simply subclassing the UICollectionViewFlowLayout class and adding UIAttachmentBehaviours to the layout attributes. The implementation is based on the "Exploring Scroll Views on iOS 7" presentation from WWDC 2013, however it goes further by providing robust memory and CPU management by tiling the UIAttachmentBehaviours.
