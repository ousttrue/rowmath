# rowmath

`zig-0.15.1`

zig math library for 3D graphics, row major

## note

ライブラリによって可換でないMatrixの乗算順が異なることに注意！

rowmath は `横vec` + `row major` なので、
乗算順は vec x (local x parent x root x view x projection) となります。

| mul order   | memory layout               | impl                                  |
| ----------- | --------------------------- | ------------------------------------- |
| 横vec x mvp | row major(m00, m01, m02...) | rowmath, DirectXMath, System.Numerics |
| pvm x 縦vec | col major(m00, m10, m20...) | glm, UnityEngine                      |

結果として Mat4 のメモリ上の内容は同じ(transpose の transpose は同じ)になる。
双方ともに `(m12, m13, m14)` に translation が格納される。

- 一般的な数学書やOpenGLドキュメントは縦vec方式
- 書籍:実例で学ぶゲーム3D数学 は横vec + row 方式

### 命名

- fromVec3, makeRotation(static 関数)
- toRotation, transformPoint(member 関数)
- add, mul, sub, eq, dot, cross

## examples

### sokol

### raylib
