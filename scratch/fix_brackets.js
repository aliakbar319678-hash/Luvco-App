const fs = require('fs');
const path = require('path');

function walkDir(dir, callback) {
  fs.readdirSync(dir).forEach(f => {
    let dirPath = path.join(dir, f);
    let isDirectory = fs.statSync(dirPath).isDirectory();
    if (isDirectory) {
      walkDir(dirPath, callback);
    } else {
      callback(dirPath);
    }
  });
}

const targetDir = path.join(__dirname, '..', 'lib', 'screens');

walkDir(targetDir, filePath => {
  if (!filePath.endsWith('.dart')) return;

  let content = fs.readFileSync(filePath, 'utf8');
  let hasCRLF = content.includes('\r\n');
  
  // Normalize line endings to LF for processing
  let lfContent = content.replace(/\r\n/g, '\n');
  let originalLf = lfContent;

  // Let's do replacements on LF content
  
  // Pattern 2: Stack/Column body where stack/column children list closes properly (has "],") but SafeArea was not closed
  // It has:
  //           ],
  //         ),
  //         ),
  //       ),
  //     );
  // Or:
  //           ],
  //         ),
  //         ),
  //       ),
  //     );
  //   }
  //
  // We want to replace it with:
  //           ],
  //         ),
  //         ),
  //         ),
  //       ),
  //     );
  
  const p2_1 = `          ],
        ),
        ),
      ),
    );`;
  const r2_1 = `          ],
        ),
        ),
        ),
      ),
    );`;

  const p2_2 = `          ],
        ),
        ),
      ),
    );
  }`;
  const r2_2 = `          ],
        ),
        ),
        ),
      ),
    );
  }`;

  const p2_3 = `              ],
            ),
            ),
          ),
        ),
      );`;
  const r2_3 = `              ],
            ),
            ),
            ),
          ),
        );`;

  // Pattern 1: Files where the children list is missing "]," and instead has ")," or ")," and SafeArea is not closed.
  // It looks like:
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  // Needs to be:
  //           ],
  //         ),
  //         ),
  //         ),
  //       ),
  //     );

  const p1_1 = `            ),
          ),
        ),
      ),
    );`;
  const r1_1 = `          ],
        ),
        ),
        ),
      ),
    );`;

  const p1_2 = `            ),
          ),
        ),
      ),
    );
  }`;
  const r1_2 = `          ],
        ),
        ),
        ),
      ),
    );
  }`;

  const p1_3 = `              ),
            ),
          ),
        ),
      );`;
  const r1_3 = `            ],
          ),
          ),
          ),
        ),
      );`;

  const p1_4 = `              ),
            ),
          ),
        ),
      );
  }`;
  const r1_4 = `            ],
          ),
          ),
          ),
        ),
      );
  }`;

  // Let's run replacements
  lfContent = lfContent.replace(p2_1, r2_1);
  lfContent = lfContent.replace(p2_2, r2_2);
  lfContent = lfContent.replace(p2_3, r2_3);
  lfContent = lfContent.replace(p1_1, r1_1);
  lfContent = lfContent.replace(p1_2, r1_2);
  lfContent = lfContent.replace(p1_3, r1_3);
  lfContent = lfContent.replace(p1_4, r1_4);

  // If there's a match, write it back with the original line endings
  if (lfContent !== originalLf) {
    let finalContent = hasCRLF ? lfContent.replace(/\n/g, '\r\n') : lfContent;
    fs.writeFileSync(filePath, finalContent, 'utf8');
    console.log(`Fixed: ${filePath}`);
  }
});
