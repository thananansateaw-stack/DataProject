import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // เพิ่มสำหรับใช้งาน Keyboard
import 'dart:math';

void main() {
  runApp(const MazeGameApp());
}

class MazeGameApp extends StatelessWidget {
  const MazeGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MazeScreen(),
    );
  }
}

class MazeScreen extends StatefulWidget {
  const MazeScreen({super.key});

  @override
  State<MazeScreen> createState() => _MazeScreenState();
}

class _MazeScreenState extends State<MazeScreen> {
  late Maze myMaze;
  // ระบบ Level Up: เริ่มด่านที่ขนาด 9x9
  int currentSize = 9;
  int currentLevel = 1;

  List<int> start = [1, 1];
  late List<int> exit;
  late List<int> playerPos;
  
  List<List<int>> hintPath = [];
  bool showHint = false;

  @override
  void initState() {
    super.initState();
    generateNewMaze();
  }

  void generateNewMaze() {
    // อัปเดตทางออกให้ไปอยู่มุมขวาล่างของขนาดตารางปัจจุบัน
    exit = [currentSize - 2, currentSize - 2];
    playerPos = [start[0], start[1]];
    
    myMaze = Maze(width: currentSize, height: currentSize);
    myMaze.digMaze(start[0], start[1]);
    
    hintPath = myMaze.findShortestPath(playerPos, exit);
    setState(() {
      showHint = false;
    });
  }

  void movePlayer(int dx, int dy) {
    int nx = playerPos[0] + dx;
    int ny = playerPos[1] + dy;

    if (myMaze.grid[ny][nx] == 0) {
      setState(() {
        playerPos = [nx, ny];
        if (showHint) {
          hintPath = myMaze.findShortestPath(playerPos, exit);
        }
      });

      // ถ้าเดินเข้าเส้นชัย (Win Condition)
      if (nx == exit[0] && ny == exit[1]) {
        showDialog(
          context: context,
          barrierDismissible: false, // บังคับให้ต้องกดปุ่ม
          builder: (context) => AlertDialog(
            title: Text("ด่านที่ $currentLevel เคลียร์! 🎉"),
            content: const Text("ไปลุยเขาวงกตที่ใหญ่ขึ้นกันเถอะ"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    currentLevel++;
                    currentSize += 2; // ขยายด่านให้ใหญ่ขึ้นทีละ 2 ช่อง
                    generateNewMaze();
                  });
                },
                child: const Text("ด่านต่อไป"),
              )
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ใช้ Focus widget เพื่อดักจับ Keyboard
    return Focus(
      autofocus: true, // สั่งให้จับตาดูการพิมพ์ตั้งแต่เปิดหน้าเว็บ
      onKeyEvent: (node, event) {
        // เช็คว่าเป็นการกดปุ่มลงไป (ไม่ใช่ตอนปล่อยปุ่ม)
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.keyW) {
            movePlayer(0, -1);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.keyS) {
            movePlayer(0, 1);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.keyA) {
            movePlayer(-1, 0);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.keyD) {
            movePlayer(1, 0);
          }
        }
        return KeyEventResult.handled;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('Maze Runner | Level $currentLevel'), // โชว์เลเวล
          backgroundColor: Colors.blueGrey[900],
          actions: [
            IconButton(
              icon: Icon(showHint ? Icons.lightbulb : Icons.lightbulb_outline),
              color: Colors.yellow,
              onPressed: () {
                setState(() {
                  showHint = !showHint;
                  if (showHint) {
                    hintPath = myMaze.findShortestPath(playerPos, exit);
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                setState(() {
                  generateNewMaze();
                });
              },
            ),
          ],
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueGrey, width: 2), // เพิ่มกรอบให้ด่าน
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: currentSize, // ปรับความกว้างตารางตามเลเวล
                  ),
                  itemCount: currentSize * currentSize, // จำนวนช่องทั้งหมด
                  itemBuilder: (context, index) {
                    int x = index % currentSize;
                    int y = index ~/ currentSize;

                    bool isPlayer = x == playerPos[0] && y == playerPos[1];
                    bool isExit = x == exit[0] && y == exit[1];
                    bool isHint = showHint && hintPath.any((p) => p[0] == x && p[1] == y);
                    bool isWall = myMaze.grid[y][x] == 1;

                    Color cellColor = Colors.white;
                    Widget? child;

                    if (isWall) {
                      cellColor = Colors.grey[800]!;
                    } else if (isPlayer) {
                      cellColor = Colors.blue;
                      child = const Icon(Icons.person, color: Colors.white, size: 12); // ปรับไอคอนให้เล็กลงนิดนึง
                    } else if (isExit) {
                      cellColor = Colors.green;
                      child = const Icon(Icons.exit_to_app, color: Colors.white, size: 12);
                    } else if (isHint && !isPlayer) {
                      cellColor = Colors.yellow[300]!;
                    }

                    return Container(
                      margin: const EdgeInsets.all(0.5),
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                      child: child,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
            // แผงควบคุมบนหน้าจอ (สำหรับมือถือ)
            const Text("ใช้คีย์บอร์ด (ลูกศร/WASD) หรือปุ่มด้านล่างเพื่อเดิน", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () => movePlayer(0, -1),
                  child: const Icon(Icons.arrow_upward),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => movePlayer(-1, 0),
                      child: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 60),
                    ElevatedButton(
                      onPressed: () => movePlayer(1, 0),
                      child: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => movePlayer(0, 1),
                  child: const Icon(Icons.arrow_downward),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ส่วนลอจิก (ไม่มีการเปลี่ยนแปลง ปลอดภัย 100%)
// ==========================================
class Maze {
  int width;
  int height;
  late List<List<int>> grid;
  Random rand = Random();

  Maze({required this.width, required this.height}) {
    grid = List.generate(height, (y) => List.generate(width, (x) => 1));
  }

  void digMaze(int startX, int startY) {
    List<List<int>> stack = [];
    grid[startY][startX] = 0;
    stack.add([startX, startY]);
    List<List<int>> directions = [[0, -2], [0, 2], [-2, 0], [2, 0]];

    while (stack.isNotEmpty) {
      List<int> current = stack.last;
      int cx = current[0];
      int cy = current[1];
      List<List<int>> validWays = [];

      for (var dir in directions) {
        int nx = cx + dir[0];
        int ny = cy + dir[1];
        if (nx > 0 && nx < width - 1 && ny > 0 && ny < height - 1) {
          if (grid[ny][nx] == 1) {
            validWays.add([nx, ny, dir[0], dir[1]]);
          }
        }
      }

      if (validWays.isNotEmpty) {
        var chosen = validWays[rand.nextInt(validWays.length)];
        int nx = chosen[0];
        int ny = chosen[1];
        int dx = chosen[2];
        int dy = chosen[3];

        grid[cy + dy ~/ 2][cx + dx ~/ 2] = 0;
        grid[ny][nx] = 0;
        stack.add([nx, ny]);
      } else {
        stack.removeLast();
      }
    }
  }

  List<List<int>> findShortestPath(List<int> start, List<int> exit) {
    List<List<int>> queue = [start];
    Set<String> visited = {"${start[0]},${start[1]}"};
    Map<String, List<int>> parentMap = {};

    while (queue.isNotEmpty) {
      List<int> current = queue.removeAt(0);
      int cx = current[0];
      int cy = current[1];

      if (cx == exit[0] && cy == exit[1]) break;

      List<List<int>> directions = [[0, -1], [0, 1], [-1, 0], [1, 0]];

      for (var dir in directions) {
        int nx = cx + dir[0];
        int ny = cy + dir[1];

        if (nx >= 0 && nx < width && ny >= 0 && ny < height && grid[ny][nx] == 0) {
          String neighborKey = "$nx,$ny";
          if (!visited.contains(neighborKey)) {
            visited.add(neighborKey);
            parentMap[neighborKey] = [cx, cy];
            queue.add([nx, ny]);
          }
        }
      }
    }

    List<List<int>> path = [];
    List<int>? current = exit;
    while (current != null) {
      path.add(current);
      current = parentMap["${current[0]},${current[1]}"];
    }
    return path.reversed.toList();
  }
}