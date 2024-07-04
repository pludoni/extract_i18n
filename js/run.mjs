import { parse, print, visit } from "recast";
import typescript from "recast/parsers/babel-ts"
import fs from "fs";

let code
if (process.argv.length == 3) {
  code = fs.readFileSync(process.argv[2], "utf-8");
}

if (!code) {
  code = fs.readFileSync(0, "utf-8");
}

if (!code) {
  console.error("Usage: node find_string_tokens.js <filename> | STDIN");
  process.exit(1);
}


const ast = parse(code, {
  parser: typescript,
})

const replacements = []

visit(ast, {
  visitLiteral(path) {
    const { node } = path;
    if (typeof node.value === "string") {
      replacements.push({
        type: 'literal',
        value: node.value,
        raw: node.raw || node.extra?.raw,
        loc: {
          start: node.loc.start,
          end: node.loc.end,
          index: node.loc.index,
        }
      })
    }
    this.traverse(path);
  },
  visitTemplateLiteral(path) {
    const { node } = path;
    replacements.push({
      type: 'template',
      quasis: node.quasis.map(quasi => ({
        value: quasi.value,
        raw: quasi.raw || quasi.extra?.raw,
        loc: {
          start: quasi.loc.start,
          end: quasi.loc.end,
          index: quasi.loc.index,
        }
      })),
      expressions: node.expressions.map(expression => ({
        loc: {
          start: expression.loc.start,
          end: expression.loc.end,
          index: expression.loc.index,
        }
      })),
    })
    this.traverse(path);
  }
  // interpolation Strings?
});
process.stdout.write(JSON.stringify(replacements, null, " "))
