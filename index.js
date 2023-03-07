import { init, WASI } from "@wasmer/wasi"
import { WasmFs } from '@wasmer/wasmfs'
import { RubyVM  } from "ruby-3_2-wasm-wasi"


const consolePrinter = () => {
  let memory = undefined;
  let view = undefined;

  const decoder = new TextDecoder();

  return {
    addToImports(imports) {
      const original = imports.wasi_snapshot_preview1.fd_write;
      imports.wasi_snapshot_preview1.fd_write = (fd, iovs, iovsLen, nwritten) => {
        if (fd !== 1 && fd !== 2) {
          return original(fd, iovs, iovsLen, nwritten);
        }

        if (typeof memory === 'undefined' || typeof view === 'undefined') {
          throw new Error('Memory is not set');
        }
        if (view.buffer.byteLength === 0) {
          view = new DataView(memory.buffer);
        }

        const buffers = Array.from({ length: iovsLen }, (_, i) => {
          const ptr = iovs + i * 8;
          const buf = view.getUint32(ptr, true);
          const bufLen = view.getUint32(ptr + 4, true);
          return new Uint8Array(memory.buffer, buf, bufLen);
        });

        let written = 0;
        let str = '';
        for (const buffer of buffers) {
          str += decoder.decode(buffer);
          written += buffer.byteLength;
        }
        view.setUint32(nwritten, written, true);

        const log = fd === 1 ? console.log : console.warn;
        log(str);

        return 0;
      };
    },
    setMemory(m) {
      memory = m;
      view = new DataView(m.buffer);
    }
  }
};


export class RubyFront {
  async init(rubyModule) {
    await init()

    const wasmFs = new WasmFs()
    const wasi = new WASI({
      env: {
        "RUBY_FIBER_MACHINE_STACK_SIZE": String(1024 * 1024 * 20),
      },
      bindings: {fs: wasmFs.fs}
    })
    const vm = new RubyVM()

    const imports = wasi.getImports(rubyModule)
    vm.addToImports(imports)

    const printer = consolePrinter()
    printer?.addToImports(imports)


    const instance = await WebAssembly.instantiate(rubyModule, imports)
    wasi.instantiate(instance)
    await vm.setInstance(instance)

    printer?.setMemory(instance.exports.memory)

    instance.exports._initialize()
    vm.initialize()
    return {vm, wasi, instance}
  }
}


const main = async() => {
  const response = await fetch(`https://cdn.jsdelivr.net/npm/ruby-3_2-wasm-wasi@1.0.1/dist/ruby+stdlib.wasm`)
  const buffer = await response.arrayBuffer()
  const module = await WebAssembly.compile(buffer)
  const { vm } = await new RubyFront().init(module)

  vm.printVersion();

  globalThis.rubyVM = vm

  const script = await fetch(`./main.rb`)
  vm.evalAsync(await script.text())
}

class PromiseFunctions {
  constructor(ok, fail) {
    this.okCb = ok
    this.failCb = fail
  }

  ok(value) {
    this.okCb(value)
  }

  fail(value) {
    this.failCb(value)
  }
}

window.NewPromise = (callback) => {
  return new Promise((ok, fail) => {
    callback(new PromiseFunctions(ok, fail))
  })
}

await main()
